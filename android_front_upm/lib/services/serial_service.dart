import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';

class SerialService {
  UsbPort? _port; // puerto serial conectado al Arduino
  StreamSubscription<String>? _subscription; // suscripción al stream de datos del puerto
  Transaction<String>? _transaction; // transacción para leer datos terminados en '\n'

  final StreamController<String> _dataController = StreamController.broadcast(); // controlador para emitir datos recibidos del Arduino
  final StreamController<bool> _connectionController = StreamController.broadcast(); // controlador para emitir cambios en el estado de conexión

  Stream<String> get dataStream => _dataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false; // estado de conexión actual
  bool get isConnected => _isConnected; // getter para el estado de conexión
  Timer? _reconnectTimer; // temporizador para intentar reconectar automáticamente

  // ------------------- Conexión y comunicación con el Arduino ------------------
  Future<void> connect() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices(); // lista de dispositivos USB conectados

      // Si no se encuentra ningún dispositivo, se considera que no hay conexión
      if (devices.isEmpty) {
        _setDisconnected();
        return;
      }

      UsbDevice device = devices.first; // se toma el primer dispositivo encontrado (se asume que es el Arduino)
      _port = await device.create(); // se crea un puerto para comunicarse con el dispositivo

      // Si no se pudo crear el puerto, se considera que no hay conexión
      if (_port == null) {
        _setDisconnected();
        return;
      }

      bool openResult = await _port!.open(); // se intenta abrir el puerto para establecer la conexión

      // Si no se pudo abrir el puerto, se considera que no hay conexión
      if (!openResult) {
        _setDisconnected();
        return;
      }

      await _port!.setDTR(true); // se activa la señal DTR para resetear el Arduino
      await _port!.setRTS(true); // se activa la señal RTS

      // Se configuran los parámetros de comunicación: velocidad de 9600 baudios, 8 bits de datos, 1 bit de parada, sin paridad
      await _port!.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      await Future.delayed(const Duration(seconds: 2)); // se espera un tiempo para que el Arduino se reinicie y esté listo para comunicarse

      // Se crea una transacción para leer datos del puerto que estén terminados en '\n'
      _transaction = Transaction.stringTerminated(
        _port!.inputStream!, // se utiliza el stream de entrada del puerto
        Uint8List.fromList([10]), // '\n'
      );

      _subscription = _transaction!.stream.listen((data) {
        _dataController.add(data);
      });

      _isConnected = true;
      _connectionController.add(true);
    } catch (e) {
      _setDisconnected();
    }
  }

  // ------------------- Desconexión y limpieza de recursos ------------------
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _transaction?.dispose();
    await _port?.close();

    _setDisconnected();
  }

  // Establece el estado de desconexión y emite un evento para notificar a los listeners
  void _setDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
  }

  // ------------------- Envío de comandos al arduino -------------------
  Future<void> send(String command) async {
    if (_port == null || !_isConnected) {
      throw Exception("Arduino not connected");
    }

    String fullCommand = "$command\n";
    await _port!.write(Uint8List.fromList(fullCommand.codeUnits));
  }

  // ------------------- Esperar respuesta del arduino -------------------
  Future<String> waitForResponse({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      String response = await dataStream.first.timeout(timeout);
      return response;
    } catch (e) {
      throw Exception("Timeout esperando respuesta del Arduino");
    }
  }

  // ------------------- Obtener sesiones del arduino -------------------
  Future<int> getSessions() async {
    await send("2");

    String response = await waitForResponse();

    final match = RegExp(r'(\d+)').firstMatch(response);

    if (match != null) {
      return int.parse(match.group(1)!);
    }

    throw Exception("Respuesta inválida: $response");
  }

  // ------------------- Obtener número de serie del arduino -------------------
  Future<String> getSerial() async {
    await send("3");

    String response = await waitForResponse();

    return response.split(":").last.trim();
  }

  // ------------------- Cargar sesiones en el arduino -------------------
  Future<void> loadSessions(int amount) async {
    await send("1");
    await waitForResponse();

    await send(amount.toString());

    await waitForResponse();
  }

  // ------------------- Establecer número de serie en el arduino -------------------
  Future<void> setSerial(String serial) async {
    await send("4");

    await waitForResponse();

    await send(serial);

    await waitForResponse();
  }

  // ------------------- Obtener total de sesiones del arduino -------------------
  Future<int> getTotalSessions() async {
    await send("5");

    String response = await waitForResponse();

    final match = RegExp(r'(\d+)').firstMatch(response);

    if (match != null) {
      return int.parse(match.group(1)!);
    }

    throw Exception("Respuesta inválida");
  }

  // ------------------- Reconexión automática -------------------
  void startAutoConnect() {
    _reconnectTimer?.cancel();

    _reconnectTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_isConnected) {
        await connect();
      }
    });
  }

  void stopAutoConnect() {
    _reconnectTimer?.cancel();
  }

  void dispose() {
    disconnect();
    _dataController.close();
    _connectionController.close();
  }
}
