import 'package:flutter/material.dart';
import 'package:front_windows_upm/home/home.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      theme: ThemeData(
        useMaterial3: true, // es para usar el nuevo diseño de Material Design 3
        colorScheme: ColorScheme.fromSeed( // el color principal de la aplicación, a partir del cual se generan otros colores
          seedColor: const Color(0xFF0066CC), // color de semilla para generar la paleta de colores
          brightness: Brightness.light, // indica que la aplicación usará un tema claro
        ),
        // Configuración del tema para el AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF004FA8),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
    );
  }
}
