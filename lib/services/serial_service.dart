import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flserial/flserial.dart';

class SerialService {
  FlSerial? _serial;
  bool _opened = false;
  bool _isOpening = false; // Evita llamadas concurrentes
  StreamSubscription<FlSerialEventArgs>? _subscription;

  final StreamController<String> _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  bool get isConnected => _opened;

  List<String> getAvailablePorts() => FlSerial.listPorts();

  /// Envía datos al Arduino
  void send(String data, {String terminator = '\n'}) {
    if (!_opened || _serial == null) return;
    final msg = '$data$terminator';
    final bytes = Uint8List.fromList(msg.codeUnits);
    try {
      _serial!.write(bytes);
      debugPrint("📤 Enviado: $data");
    } catch (e) {
      debugPrint("❌ Error enviando datos: $e");
    }
  }

  /// Cierra el puerto y la escucha
  void close() {
    if (!_opened || _serial == null) return;
    try {
      _subscription?.cancel();
      _serial!.closePort();
      _serial!.free();
      debugPrint("🔌 Puerto cerrado");
    } catch (e) {
      debugPrint("❌ Error cerrando puerto: $e");
    }
    _opened = false;
  }

  /// Comienza a escuchar los datos entrantes
  void _startListening() {
    _subscription?.cancel();
    _subscription = _serial?.onSerialData.stream.listen((args) {
      if (args.len > 0) {
        final text = String.fromCharCodes(args.serial.readList());
        final lines = text.split('\n');
        for (var line in lines) {
          line = line.trim();
          if (line.isNotEmpty) {
            debugPrint("📥 Dato recibido: $line");
            _controller.add(line);
          }
        }
      }
    });
  }

  /// Abre el puerto con delay opcional
  Future<bool> open(String portName, {int baudRate = 9600}) async {
    if (_isOpening) return false; // Bloquea apertura concurrente
    _isOpening = true;
    debugPrint("⏳ Esperando 2s antes de abrir puerto $portName");
    await Future.delayed(const Duration(seconds: 2));

    try {
      debugPrint("🔌 Intentando abrir puerto: $portName");

      // Cerrar cualquier puerto previo
      try {
        _subscription?.cancel();
        _serial?.closePort();
        _serial?.free();
      } catch (_) {}

      _opened = false;
      _serial = FlSerial();
      _serial!.init();

      // Abrir puerto y reset tipo Arduino IDE
      _serial!.openPort(portName, baudRate);
      _serial!.setDTR(true);
      await Future.delayed(const Duration(milliseconds: 100));
      _serial!.setDTR(false);

      // Espera a que Arduino arranque
      await Future.delayed(const Duration(seconds: 2));

      // Inicia escucha
      _startListening();

      _opened = true;
      debugPrint("✅ Puerto abierto correctamente: $portName");
      return true;
    } catch (e) {
      debugPrint("❌ Error abriendo puerto: $e");
      _opened = false;
      return false;
    } finally {
      _isOpening = false;
    }
  }

  /// Reconecta al puerto
  Future<bool> reconnect(String portName, {int baudRate = 9600}) async {
    debugPrint("🔄 Reconectando a puerto: $portName");
    close();
    await Future.delayed(const Duration(milliseconds: 500));
    return open(portName, baudRate: baudRate);
  }
}