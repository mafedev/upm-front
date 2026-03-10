import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter/foundation.dart';

class SerialService {
  SerialPort? _port;
  Timer? _readTimer;

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  bool open(String portName) {
    _port = SerialPort(portName);
    if (!_port!.openReadWrite()) {
      debugPrint("Error al abrir puerto");
      return false;
    }

    _port!.config.baudRate = 9600;
    _port!.config.bits = 8;
    _port!.config.stopBits = 1;
    _port!.config.parity = SerialPortParity.none;

    _startReading();
    debugPrint("Puerto configurado correctamente");
    return true;
  }

  void _startReading() {
    _readTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_port == null || !_port!.isOpen) return;
      try {
        final bytes = _port!.read(1024);
        if (bytes.isNotEmpty) {
          final text = String.fromCharCodes(bytes).trim();
          if (text.isNotEmpty) _controller.add(text);
        }
      } catch (e) {
        debugPrint("Error en puerto: $e");
      }
    });
  }

  void send(String data) {
    if (_port == null || !_port!.isOpen) return;
    final message = "$data\n";
    final bytes = Uint8List.fromList(message.codeUnits);
    _port!.write(bytes);
  }

  /// Send a string with a custom terminator (e.g. '\r\n').
  void sendWithTerminator(String data, {String terminator = '\n'}) {
    if (_port == null || !_port!.isOpen) return;
    final message = '$data$terminator';
    final bytes = Uint8List.fromList(message.codeUnits);
    _port!.write(bytes);
    debugPrint('SerialService: sent (${bytes.length}) bytes: $message');
  }

  List<String> getAvailablePorts() => SerialPort.availablePorts;

  void close() {
    _readTimer?.cancel();
    _controller.close();
    _port?.close();
  }
}
