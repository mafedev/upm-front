import 'dart:async';
import 'dart:typed_data';
import 'serial_service.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';

class SerialAndroidService implements SerialService {
  UsbPort? _port;
  Transaction<String>? _transaction;
  StreamSubscription<String>? _subscription;

  final StreamController<String> _dataController =
      StreamController.broadcast();

  final StreamController<bool> _connectionController =
      StreamController.broadcast();

  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  // ---------------- CONNECT ----------------

  @override
  Future<void> connect() async {
    final devices = await UsbSerial.listDevices();

    if (devices.isEmpty) {
      _setDisconnected();
      return;
    }

    final device = devices.first;

    _port = await device.create();

    if (_port == null) {
      _setDisconnected();
      return;
    }

    final opened = await _port!.open();

    if (!opened) {
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

    _subscription = _transaction!.stream.listen((line) {
      final clean = line.trim();
      if (clean.isNotEmpty) {
        _dataController.add(clean);
      }
    });

    _isConnected = true;
    _connectionController.add(true);
  }

  // ---------------- DISCONNECT ----------------

  @override
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

  @override
  Future<void> send(String command) async {
    if (_port == null || !_isConnected) return;

    final full = "$command\n";
    _port!.write(Uint8List.fromList(full.codeUnits));
  }

  // ---------------- AUTO CONNECT ----------------

  Timer? _reconnectTimer;

  @override
  void startAutoConnect() {
    _reconnectTimer?.cancel();

    _reconnectTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_isConnected) {
        await connect();
      }
    });
  }

  @override
  void stopAutoConnect() {
    _reconnectTimer?.cancel();
  }

  // ---------------- DISPOSE ----------------

  @override
  void dispose() {
    disconnect();
    _dataController.close();
    _connectionController.close();
  }
  
  @override
  // TODO: implement puertoActual
  String? get puertoActual => null;
}