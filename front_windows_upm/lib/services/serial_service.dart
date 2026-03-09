import 'dart:async';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter/foundation.dart';

class SerialService {
  SerialPort? _port; // puerto abierto
  Timer? _readTimer; // es el que lee el puerto

  // Controlador que permite enviar datos al Home
  // broadcast es para que pueda haber más de un listener escuchando
  final StreamController<String> _controller = StreamController<String>.broadcast();

  // Permiten que se escuchen los datos desde fuera
  Stream<String> get stream => _controller.stream;

  // ---------- Abrir puerto ----------
  // Abre el puerto usando su nombre
  bool open(String portName) {
    _port = SerialPort(portName); // Se crea el puerto

    // Se abre en lectura y escritura, si falla, muestra el mensaje y se devuelve un false
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

    // Se comienza a leer cada 100ms para evitar problemas
    _startReading();

    return true; // indica que todo salió bien
  }

  // ---------- Lectura de los datos ----------
  void _startReading() {
    // timer que se ejecuta cada 100ms
    _readTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      try {
        // si el puerto no existe o no está abierto, sale
        if (_port == null || !_port!.isOpen) return;
        
        final bytes = _port!.read(1024);

        // si llegaron datos
        if (bytes.isNotEmpty) {
          // se convierten de bytes a texto
          final text = String.fromCharCodes(bytes).trim();

          // si no está vacío
          if (text.isNotEmpty) {
            debugPrint("Recibido: $text"); // muestra lo que recibió
            _controller.add(text); // envia el texto al stream para que lo muestre el Home
          }
        }
      } catch (e) {
        debugPrint("Error en el puerto: $e");
      }
    });
  }

  // ---------- Enviar datos ----------
  void send(String data) {
    // Al igual que antes, si no existe o no está abierto, sale
    if (_port == null || !_port!.isOpen) return;

    final message = "$data\n"; // Agrega el salto de línea al final
    final bytes = Uint8List.fromList(message.codeUnits); // se pasa el texto a bytes

    _port!.write(bytes); // escribe y envía los bytes
  }

  // Devuelve la lista de puertos dispopnibles
  List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }

  // Cierra todo cuando ya no se usa
  void close() {
    _readTimer?.cancel(); // se detiene el timer
    _controller.close(); // se cierra el stream
    _port?.close(); // cierra el puerto
  }
}
