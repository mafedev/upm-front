import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:typed_data';

// Se encarga de manejar todo lo relacionado con el puerto serial
class SerialService {
  SerialPort? _port; // puerto abierto
  SerialPortReader? _reader; // es el que lee los datos que envía el Arduino

  // ---------- Abrir puerto ----------
  // Abre el puerto usando su nombre
  bool open(String portName) {
    _port = SerialPort(portName); // Se crea el puerto

    // Se abre en rectura y escritura, si falla, muestra el mensaje y se devuelve un false
    if (!_port!.openReadWrite()) {
      debugPrint("Error al abrir puerto");
      return false;
    }

    // ----- Configuración del puerto -----
    _port!.config.baudRate = 9600; // velocidad
    _port!.config.bits = 8; // 8 bits por byte
    _port!.config.stopBits = 1; // 1 bit de stop
    _port!.config.parity = SerialPortParity.none; // sin paridad

    debugPrint("Puerto configurado correctamente");

    // Escucha los datos entrantes, es lo que permite poder acceder a ellos como Stream
    _reader = SerialPortReader(_port!);

    return true; // devuelve true si todo salió bien
  }

  // ---------- Enviar datos ----------
  void send(String data) {
    final message = "$data\n"; // Agrega un salto de línea al final
    // Luego convierte cada crácter en su valor ASCII, y convierte esa lista en un tipo que Flutter pueda enviar por el puerto
    final bytes = Uint8List.fromList(message.codeUnits);
    _port!.write(bytes); // envía los bytes
  }

  // ---------- Lectura de datos ----------
  // Escucha los datos entrantes
  Stream<String> get stream async* {
    if (_reader == null) return; // si no hay reader se sale
    // Si hay datos, los lee en bytes y los pasa a String
    await for (final data in _reader!.stream) {
      yield String.fromCharCodes(data);
    }
  }

  // Cierra el puerto y el lector cuando ya no se usan
  void close() {
    _reader?.close();
    _port?.close();
  }
}
