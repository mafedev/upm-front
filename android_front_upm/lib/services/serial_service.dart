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

  // ---------------- CONNECT ----------------

  Future<void> connect() async {
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

    _transaction = Transaction.stringTerminated(
      _port!.inputStream!,
      Uint8List.fromList([10]), // '\n'
    );

    _subscription = _transaction!.stream.listen((data) {
      _dataController.add(data);
    });

    _isConnected = true;
    _connectionController.add(true);
  }

  // ---------------- DISCONNECT ----------------

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

  // ---------------- SEND ----------------

  Future<void> send(String command) async {
    if (_port == null || !_isConnected) return;

    String fullCommand = "$command\n";
    _port!.write(Uint8List.fromList(fullCommand.codeUnits));
  }

  // ---------------- AUTO RECONNECT ----------------

  Timer? _reconnectTimer;

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

  // ---------------- DISPOSE ----------------

  void dispose() {
    disconnect();
    _dataController.close();
    _connectionController.close();
  }
}