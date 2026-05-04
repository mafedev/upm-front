import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  final String baseUrl;

  AdminService({required this.baseUrl});

  Map<String, String> get _headers => {"Content-Type": "application/json"};

  void _handleError(http.Response res) {
    throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  Future<bool> deviceExists(String serial) async {
    final url = '$baseUrl/api/device/status/$serial';

    final res = await http.get(Uri.parse(url), headers: _headers);

    if (res.statusCode == 200) return true;
    if (res.statusCode == 404) return false;

    _handleError(res);
    return false;
  }

  Future<int> getPendingSessions(String serial) async {
    final url = '$baseUrl/api/device/sessions/pending/$serial';

    final res = await http.get(Uri.parse(url), headers: _headers);

    if (res.statusCode != 200) {
      _handleError(res);
    }

    return int.tryParse(res.body) ?? 0;
  }

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
