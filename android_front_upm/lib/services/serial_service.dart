import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';

class SerialService {
  UsbPort? _port;
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;

  final StreamController<String> _dataController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();

  Stream<String> get dataStream => _dataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Timer? _reconnectTimer;

  Future<void> connect() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        _setDisconnected();
        return;
      }

      UsbDevice device = devices.first;

      _port = await device.create();

      if (_port == null) {
        _setDisconnected();
        return;
      }

      bool openResult = await _port!.open();

      if (!openResult) {
        _setDisconnected();
        return;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);

      await _port!.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      await Future.delayed(const Duration(seconds: 2));

      _transaction = Transaction.stringTerminated(
        _port!.inputStream!,
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

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _transaction?.dispose();
    await _port?.close();

    _setDisconnected();
  }

  void _setDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
  }

  Future<void> send(String command) async {
    if (_port == null || !_isConnected) {
      throw Exception("Arduino not connected");
    }

    String fullCommand = "$command\n";
    await _port!.write(Uint8List.fromList(fullCommand.codeUnits));
  }

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

  Future<int> getSessions() async {
    await send("2");

    String response = await waitForResponse();

    final match = RegExp(r'(\d+)').firstMatch(response);

    if (match != null) {
      return int.parse(match.group(1)!);
    }

    throw Exception("Respuesta inválida: $response");
  }

  Future<String> getSerial() async {
    await send("3");

    String response = await waitForResponse();

    return response.split(":").last.trim();
  }

  Future<void> loadSessions(int amount) async {
    await send("1");
    await waitForResponse();

    await send(amount.toString());

    await waitForResponse();
  }

  Future<void> setSerial(String serial) async {
    await send("4");

    await waitForResponse();

    await send(serial);

    await waitForResponse();
  }

  Future<int> getTotalSessions() async {
    await send("5");

    String response = await waitForResponse();

    final match = RegExp(r'(\d+)').firstMatch(response);

    if (match != null) {
      return int.parse(match.group(1)!);
    }

    throw Exception("Respuesta inválida");
  }

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
