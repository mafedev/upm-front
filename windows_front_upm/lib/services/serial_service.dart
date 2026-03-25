import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flserial/flserial.dart';

class SerialService {
  FlSerial? _serial;
  bool _opened = false;

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  // Lista los nombres de puertos disponibles
  List<String> getAvailablePorts() {
    return FlSerial.listPorts();
  }

  // Abre el puerto
  bool open(String portName, {int baudRate = 9600}) {
    try {
      _serial = FlSerial();
      _serial!.init();
      _serial!.openPort(portName, baudRate);

      // Escuchar datos
      _serial!.onSerialData.stream.listen((args) {
        if (args.len > 0) {
          final bytes = args.serial.readList();
          final text = String.fromCharCodes(bytes).trim();
          if (text.isNotEmpty) _controller.add(text);
        }
      });

      _opened = true;
      debugPrint("Puerto abierto: $portName");
      return true;
    } catch (e) {
      debugPrint("Error abriendo puerto: $e");
      return false;
    }
  }

  // Envía datos
  void send(String data, {String terminator = '\n'}) {
    if (!_opened || _serial == null) return;
    final msg = '$data$terminator';
    final bytes = Uint8List.fromList(msg.codeUnits);
    try {
      _serial!.write(bytes);
    } catch (e) {
      debugPrint("Error enviando datos: $e");
    }
  }

  // Cierra el puerto
  void close() {
    if (!_opened || _serial == null) return;
    try {
      _serial!.closePort();
      _serial!.free();
    } catch (e) {
      debugPrint("Error cerrando puerto: $e");
    }
    _opened = false;
  }
}