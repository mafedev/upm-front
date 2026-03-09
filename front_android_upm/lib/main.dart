import 'package:flutter/material.dart';
import 'package:front_upm/home/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      theme: ThemeData(
        useMaterial3: true, // es para usar el nuevo diseño de Material Design 3
        // Definir un esquema de colores personalizado
        colorScheme: ColorScheme.fromSeed(
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