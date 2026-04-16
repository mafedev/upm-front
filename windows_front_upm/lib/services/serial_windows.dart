import 'dart:async';
import 'serial_service.dart';

class WindowsSerialService implements SerialService {
  final StreamController<String> _dataController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();

  String? _currentPort;
  bool _connected = false;
  Timer? _autoConnectTimer;
  Timer? _broadcastTimer;

  // Simulated device state (for Windows simulation)
  int _sesiones = 5;
  int _total = 10;
  String _serialStr = '1234';
  String _estado = 'INACTIVO';

  // ---------- Getters ----------
  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStream => _connectionController.stream;

  @override
  bool get isConnected => _connected;

  String? get puertoActual => _currentPort; // <-- getter del puerto conectado

  // ---------- Conectar ----------
  @override
  Future<void> connect() async {
    // Aquí iría la lógica real para abrir el puerto serie
    // Por ejemplo: buscar puertos disponibles y abrir uno
    _currentPort = "COM3"; // ejemplo
    _connected = true;
    _connectionController.add(_connected);

    // Simulación de datos entrantes: emitir estado cada segundo
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_connected) {
        t.cancel();
        return;
      }

      _dataController.add('SESIONES:${_sesiones},TOTAL:${_total},SERIAL:${_serialStr}');
    });
  }

  // ---------- Desconectar ----------
  @override
  Future<void> disconnect() async {
    _connected = false;
    _connectionController.add(_connected);
    _currentPort = null;
  }

  // ---------- Enviar comando ----------
  @override
  Future<void> send(String command) async {
    if (!_connected) return;
    final cmd = command.trim();
    print("Enviando al Arduino: $cmd");

    final up = cmd.toUpperCase();

    if (up.startsWith('SET_SESIONES:')) {
      final valStr = cmd.substring(13).trim();
      final val = int.tryParse(valStr) ?? 0;
      _sesiones = val;
      _dataController.add('OK');
      _dataController.add('SESIONES:$_sesiones');
      return;
    }

    if (up == 'GET_SESIONES') {
      _dataController.add('SESIONES:$_sesiones');
      return;
    }

    if (up == 'GET_SERIAL') {
      _dataController.add('SERIAL:$_serialStr');
      return;
    }

    if (up.startsWith('SET_SERIAL:')) {
      final s = cmd.substring(11).trim();
      _serialStr = s;
      _dataController.add('OK');
      _dataController.add('SERIAL:$_serialStr');
      return;
    }

    if (up == 'GET_TOTAL') {
      _dataController.add('TOTAL:$_total');
      return;
    }

    if (up.startsWith('RESET_TOTAL:')) {
      final code = int.tryParse(cmd.substring(12).trim());
      if (code == 1234) {
        _total = 0;
        _dataController.add('OK');
        _dataController.add('TOTAL:$_total');
      } else {
        _dataController.add('ERROR');
      }
      return;
    }

    if (up == 'GET_ESTADO') {
      _dataController.add('ESTADO:$_estado');
      return;
    }

    // Comando desconocido
    _dataController.add('ERROR:CMD');
  }

  // ---------- Auto conexión ----------
  @override
  void startAutoConnect() {
    _autoConnectTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_connected) connect();
    });
  }

  @override
  void stopAutoConnect() {
    _autoConnectTimer?.cancel();
    _broadcastTimer?.cancel();
  }

  // ---------- Limpiar recursos ----------
  @override
  void dispose() {
    stopAutoConnect();
    _dataController.close();
    _connectionController.close();
  }
}