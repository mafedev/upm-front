import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  final String baseUrl;
  final String token;

  AdminService({required this.baseUrl, required this.token});

  Map<String, String> get _adminHeaders => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  Map<String, String> get _publicHeaders => {
    "Content-Type": "application/json",
  };

  void _handleError(http.Response res) {
    throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  Future<List<Map<String, dynamic>>> getDevices() async {
    final url = '$baseUrl/api/admin/devices';

    final res = await http.get(Uri.parse(url), headers: _adminHeaders);

    if (res.statusCode != 200) {
      _handleError(res);
    }

    final List data = jsonDecode(res.body);

    return data.map<Map<String, dynamic>>((e) => {"serialNumber": e["serialNumber"], "ownerName": e["ownerName"],}).toList();
  }

  Future<Map<String, dynamic>> getStatus(String serial) async {
    final url = '$baseUrl/api/device/status/$serial';

    final res = await http.get(Uri.parse(url), headers: _publicHeaders);

    if (res.statusCode != 200) {
      _handleError(res);
    }

    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getHistory(String serial) async {
    final url = '$baseUrl/api/history/$serial';

    final res = await http.get(Uri.parse(url), headers: _publicHeaders);

    if (res.statusCode != 200) {
      _handleError(res);
    }

    return jsonDecode(res.body);
  }

  Future<void> createDevice(String serial, String owner) async {
    final url = '$baseUrl/api/admin/devices';

    final body = {"serialNumber": serial, "ownerName": owner};

    final res = await http.post(
      Uri.parse(url),
      headers: _adminHeaders,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      _handleError(res);
    }
  }

  Future<void> deleteDevice(String serial) async {
    final url = '$baseUrl/api/admin/devices/$serial';

    final res = await http.delete(Uri.parse(url), headers: _adminHeaders);

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }

  Future<void> rechargeSessions(String serial, int amount) async {
    final url = '$baseUrl/api/admin/sessions/recharge';

    final body = {"serialNumber": serial, "amount": amount};

    final res = await http.post(
      Uri.parse(url),
      headers: _adminHeaders,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }
  }

  Future<String> transferAllToArduino(String serial) async {
    final url = '$baseUrl/api/device/transfer';

    final body = {"serialNumber": serial};

    final res = await http.post(
      Uri.parse(url),
      headers: _publicHeaders,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      _handleError(res);
    }

    return res.body;
  }

  Future<int> getPendingSessions(String serial) async {
    final url = '$baseUrl/api/device/sessions/pending/$serial';

    final res = await http.get(Uri.parse(url), headers: _publicHeaders);

    if (res.statusCode != 200) {
      _handleError(res);
    }

    return int.tryParse(res.body) ?? 0;
  }
}
