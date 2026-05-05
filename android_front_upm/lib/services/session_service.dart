import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionService {
  final String baseUrl;

  SessionService({required this.baseUrl});

  Map<String, String> get _headers => {"Content-Type": "application/json"}; // Encabezados comunes para las solicitudes HTTP

  // Maneja errores HTTP lanzando una excepción con el código de estado y el cuerpo de la respuesta
  void _handleError(http.Response res) {
    throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  // Verifica si un dispositivo con el número de serie dado existe en el sistema
  Future<bool> deviceExists(String serial) async {
    final url = '$baseUrl/api/device/status/$serial';

    final res = await http.get(Uri.parse(url), headers: _headers);

    if (res.statusCode == 200) return true;
    if (res.statusCode == 404) return false;

    _handleError(res);
    return false;
  }

  // Obtiene el número de sesiones pendientes para un dispositivo con el número de serie dado
  Future<int> getPendingSessions(String serial) async {
    final url = '$baseUrl/api/device/sessions/pending/$serial';

    final res = await http.get(Uri.parse(url), headers: _headers);

    if (res.statusCode != 200) {
      _handleError(res);
    }

    return int.tryParse(res.body) ?? 0;
  }

  // Confirma la transferencia de un dispositivo con el número de serie dado
  Future<void> confirmTransfer(String serial) async {
    final url = '$baseUrl/api/device/transfer';

    final res = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({"serialNumber": serial}),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }
}
