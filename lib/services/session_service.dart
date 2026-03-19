import 'package:flutter/foundation.dart';

class SessionService extends ChangeNotifier {
  final String _password = "1234"; // Contraseña fija

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  // ---------- Iniciar sesión ----------
  void login(String inputPassword) {
    if (inputPassword.trim() == _password) {
      _authenticated = true;
      notifyListeners(); // notifica a la UI
    }
  }

  // ---------- Cerrar sesión ----------
  void logout() {
    _authenticated = false;
    notifyListeners();
  }
}
