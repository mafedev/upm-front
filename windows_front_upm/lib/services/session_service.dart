import 'package:flutter/foundation.dart';

class SessionService extends ChangeNotifier {
  String _password = "1234"; // Contraseña

  bool _authenticated = false; // guarda el estado de autenticación, inicialmente es falso porque no se ha iniciado sesión
  bool get authenticated => _authenticated; // getter para acceder al estado de autenticación desde otras partes de la app

  // ---------- Iniciar sesión ----------
  void login(String inputPassword) {
    
    if (inputPassword.trim() == _password) { // si la contraseña ingresada es correcta
      _authenticated = true;  // se cambia el estado de autenticación a verdadero
      notifyListeners(); // notifica a los listeners para que actualicen la UI
    }
  }

  // ---------- Cerrar sesión ----------
  void logout() {
    _authenticated = false; // se cambia el estado de autenticación a falso
    notifyListeners(); // notifica a los listeners para que actualicen la UI
  }
}