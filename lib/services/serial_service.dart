import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

class SerialService {
  UsbPort? _port;
  UsbDevice? _device;
  StreamSubscription<Uint8List>? _subscription;
  bool _opened = false;

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  /// Lista los dispositivos USB disponibles
  Future<List<UsbDevice>> getAvailableDevices() async {
    return await UsbSerial.listDevices();
  }

  /// Abre el puerto
  Future<bool> open(UsbDevice device, {int baudRate = 9600}) async {
    try {
      _device = device;
      _port = await device.create();
      if (_port == null) {
        debugPrint("No se pudo crear el puerto");
        return false;
      }

      bool opened = await _port!.open();
      if (!opened) {
        debugPrint("Error abriendo puerto");
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // Escuchar datos
      _subscription = _port!.inputStream?.listen((data) {
        if (data.isNotEmpty) {
          final text = String.fromCharCodes(data).trim();
          if (text.isNotEmpty) _controller.add(text);
        }
      });

      _opened = true;
      debugPrint("Puerto abierto: ${device.productName}");
      return true;
    } catch (e) {
      debugPrint("Error abriendo puerto: $e");
      return false;
    }
  }

  /// Envía datos
  Future<void> send(String data, {String terminator = '\n'}) async {
  if (!_opened || _port == null) return;
  final msg = '$data$terminator';
  final bytes = Uint8List.fromList(msg.codeUnits);
  try {
    _port!.write(bytes);
  } catch (e) {
    debugPrint("Error enviando datos: $e");
  }
}

  /// Cierra el puerto
  Future<void> close() async {
    if (!_opened || _port == null) return;
    try {
      await _subscription?.cancel();
      await _port!.close();
      _port = null;
      _device = null;
    } catch (e) {
      debugPrint("Error cerrando puerto: $e");
    }
    _opened = false;
  }
}