abstract class SerialService {
  /// Stream de datos entrantes (líneas del Arduino)
  Stream<String> get dataStream;

  /// Estado de conexión
  Stream<bool> get connectionStream;

  bool get isConnected;

  /// Conectar
  Future<void> connect();

  /// Desconectar
  Future<void> disconnect();

  /// Enviar comando (ej: SET_SESIONES:10)
  Future<void> send(String command);

  /// Auto conexión (opcional en Android)
  void startAutoConnect();

  void stopAutoConnect();

  /// Liberar recursos
  void dispose();

  String? get puertoActual;
}