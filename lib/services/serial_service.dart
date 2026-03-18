import 'dart:async';
import 'dart:typed_data';
import 'package:flserial/flserial.dart';
import 'package:flutter/foundation.dart';

class SerialService {
  FlSerial? _serial;
  bool _opened = false;
  String? _currentPort;
  int baudRate;

  final StreamController<String> _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  final StreamController<String?> _portController = StreamController<String?>.broadcast();
  Stream<String?> get portStream => _portController.stream;

  Timer? _scanTimer;
  bool _isOpening = false;

  String? get currentPort => _currentPort;

  SerialService({this.baudRate = 9600}) {
    _init();
  }

  Future<void> _init() async {
    // 🔴 CLAVE: esperar a que Windows monte el USB
    await Future.delayed(const Duration(seconds: 2));

    _scanTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _scanPorts(),
    );
  }

  List<String> getAvailablePorts() => FlSerial.listPorts();

  Future<void> _scanPorts() async {
    if (_isOpening) return;

    final ports = getAvailablePorts();

    if (ports.isEmpty) {
      _closePort();
      _portController.add(null);
      return;
    }

    final portName = ports.first.split(' - ').first.trim();

    // Si ya está abierto y es el mismo → no hacer nada
    if (_opened && _currentPort == portName) return;

    await _tryOpenPort(portName);
  }

  Future<void> _tryOpenPort(String portName) async {
    if (_isOpening) return;

    _isOpening = true;

    try {
      // 🔴 Siempre limpiar antes de abrir
      try {
        _serial?.closePort();
        _serial?.free();
      } catch (_) {}

      _serial = FlSerial();
      _serial!.init();

      // 🔴 pequeño delay antes de abrir
      await Future.delayed(const Duration(milliseconds: 300));

      _serial!.openPort(portName, baudRate);

      // 🔴 RESET tipo Serial Monitor
      _serial!.setDTR(true);
      await Future.delayed(const Duration(milliseconds: 100));
      _serial!.setDTR(false);

      // 🔴 esperar a que Arduino arranque
      await Future.delayed(const Duration(seconds: 2));

      _currentPort = portName;
      _opened = true;

      _portController.add(_currentPort);

      _serial!.onSerialData.stream.listen((args) {
  if (args.len > 0) {
    final text = String.fromCharCodes(args.serial.readList());
    print("RAW: $text"); // 🔴 DEBUG BRUTO

    final lines = text.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        _controller.add(line);
      }
    }
  }
});

      debugPrint("✅ Puerto abierto correctamente: $portName");
    } catch (e) {
      debugPrint("❌ Error abriendo puerto: $e");

      _opened = false;
      _currentPort = null;
      _portController.add(null);
    }

    _isOpening = false;
  }

  void send(String data, {String terminator = '\n'}) {
    if (!_opened || _serial == null) {
      debugPrint("⚠️ No hay puerto abierto");
      return;
    }

    try {
      _serial!.write(Uint8List.fromList('$data$terminator'.codeUnits));
      debugPrint("➡️ Enviado: $data");
    } catch (e) {
      debugPrint("❌ Error enviando: $e");
      _opened = false;
      _currentPort = null;
      _portController.add(null);
    }
  }

  void _closePort() {
    if (!_opened || _serial == null) return;

    try {
      _serial!.closePort();
      _serial!.free();
    } catch (e) {
      debugPrint("Error cerrando puerto: $e");
    }

    _opened = false;
    _currentPort = null;
  }

  void close() {
    _scanTimer?.cancel();
    _closePort();
    _portController.close();
    _controller.close();
  }
}