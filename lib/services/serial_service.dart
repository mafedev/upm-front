import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:typed_data';

class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;

  bool open(String portName) {
  _port = SerialPort(portName);

  if (!_port!.openReadWrite()) {
    print("Error al abrir puerto");
    return false;
  }

  _port!.config.baudRate = 9600;
  _port!.config.bits = 8;
  _port!.config.stopBits = 1;
  _port!.config.parity = SerialPortParity.none;

  print("Puerto configurado correctamente");

  _reader = SerialPortReader(_port!);

  return true;
}

  void send(String data) {
  final message = "$data\n";
  final bytes = Uint8List.fromList(message.codeUnits);
  _port!.write(bytes);
}

  Stream<String> get stream async* {
    if (_reader == null) return;
    await for (final data in _reader!.stream) {
      yield String.fromCharCodes(data);
    }
  }

  void close() {
    _reader?.close();
    _port?.close();
  }
}