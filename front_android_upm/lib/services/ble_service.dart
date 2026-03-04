import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  // Dispositivo al que nos vamos a conectar, es decir, al BLE del Arduino
  // es ? porque al principio no se estamos conectados a nada
  BluetoothDevice? _device;
  
  // Como en BLE no se envían los datos directamente, entonces tnemeos que usar las characteristics
  BluetoothCharacteristic? _commandChar; // característica para enviar datos al Arduino
  BluetoothCharacteristic? _responseChar; // característica para recibir datos del Arduino

  // Crea un canal interno para emitir datos hacia la interfaz
  final StreamController<String> _controller = StreamController<String>.broadcast(); // broadcast para poder tener más de un listener

  Stream<String> get stream => _controller.stream; // Expone el Stream, permite escuchar desde fuera los datos recibidos

  // Servicio del Arduino
  final Guid serviceUuid = Guid("00000000-0000-0000-0000-0000000000ab");

  final Guid commandUuid = Guid("11111111-1111-1111-1111-111111111111");

  final Guid responseUuid = Guid("22222222-2222-2222-2222-222222222222");

  // ------------ Conecta al dispositivo BLE ------------
  Future<void> connect() async {

  await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

  ScanResult? target;

  await for (var results in FlutterBluePlus.scanResults) {
    for (ScanResult r in results) {
      if (r.device.name == "CTB-UPM") {
        target = r;
        break;
      }
    }
    if (target != null) break;
  }

  if (target == null) {
    print("No se encontró el dispositivo");
    return;
  }

  await FlutterBluePlus.stopScan();

  _device = target.device;

  await _device!.connect();
  print("Conectado al dispositivo");

  await _discoverServices();

  print("Servicios descubiertos");
}

  // ------------ Descubre servicios y características ------------
  // En BLE los datos no se envían directamente, sino a través de características, entonces después de conectarse se tienen que descubrir qué características tiene para poder enviar y recibir datos
  Future<void> _discoverServices() async {
    
    // le pide al Arduino una lista de los servicios BLE que tiene
    List<BluetoothService> services = await _device!.discoverServices();

    // itera sobre cada servicio para encontrar el que tiene el UUID que hemos definido
    for (var service in services) {
      // Si coincide
      if (service.uuid == serviceUuid) {
        // Itera las características
        for (var characteristic in service.characteristics) {
          print("Servicio: ${service.uuid}");
          print("Characteristic: ${characteristic.uuid}");

          // Si encuentra la característica para enviar comandos, la guarda 
          if (characteristic.uuid == commandUuid) {
            _commandChar = characteristic;
          }

          // Si encuentra la característica para recibir respuestas, la guarda y se suscribe a ella para escuchar los datos que envía el Arduino
          if (characteristic.uuid == responseUuid) {
            print("Servicio encontrado: ${service.uuid}");
            print("Characteristic encontrada: ${characteristic.uuid}");

            _responseChar = characteristic;
            await _responseChar!.setNotifyValue(true); // activa las notificaciones para poder recibir los datos automáticamente
            
            // escucha cada vez que el Arudino envía algo
            _responseChar!.lastValueStream.listen((value) {
              final text = utf8.decode(value); // pasa los bytes a texto
              _controller.add(text); // envia el texto usando el stream
            });
          }
        }
      }
    }
  }

  // ------------ Envíar datos al Arduino ------------
  Future<void> send(String message) async {
  if (_commandChar == null) {
    print("No conectado aún");
    return;
  }

  print("Enviando: $message");
  await _commandChar!.write(
    utf8.encode(message),
    withoutResponse: false,
  );
}

  // ------------ Desconecta del dispositivo BLE ------------
  Future<void> disconnect() async {
    await _device?.disconnect();
    _controller.close();
  }
}