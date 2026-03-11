import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'services/serial_service.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'widgets/navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Se encarga de inicializar los bindings de Flutter

  // Configuración de la ventana para Windows
  // Es necesario porque de lo contrario al cambiar el tamaño de la ventana se recarga toda la app y la app se rompe
  
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) { // verifica que no esté en web y que el sistema operativo sea Windows
    await windowManager.ensureInitialized(); // inicializa el window manager, es el encargado de manejar la ventana en Windows

    // Configura las opciones de la ventana, como el tamaño, el título, etc
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 700), // tamaño inicial de la ventana
      minimumSize: Size(900, 650), // tamaño mínimo de la ventana
      center: true, // centra la ventana en la pantalla
      title: "CTB-UPM", // título de la ventana
    );

    // Espera a que la ventana esté lista para mostrarse, luego la muestra y le da el foco
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show(); // muestra la ventana
      await windowManager.focus(); // le da el foco a la ventana
    });
  }

  // Inicializa el servicio de comunicación serial, que se encargará de manejar la comunicación con el dispositivo conectado por puerto serie
  final serialService = SerialService();

  // Detecta el puerto automáticamente
  String puertoDetectado = "No detectado";
  final ports = serialService.getAvailablePorts();
  if (ports.isNotEmpty) {
    puertoDetectado = ports.first.split(' - ').first.trim();
    serialService.open(puertoDetectado);
  }

  runApp(MainApp(
    serialService: serialService, // pasa el servicio
    puertoArduino: puertoDetectado, // pasa el puerto detectado
  ));
}

class MainApp extends StatefulWidget {
  final SerialService serialService;
  final String puertoArduino; // puerto detectado para mostrar en la UI

  const MainApp({super.key, required this.serialService, required this.puertoArduino});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int index = 0; // índice para controlar la pantalla actual, 0 para HomeScreen y 1 para AdminScreen


  @override
  Widget build(BuildContext context) {

    // Lista de pantallas disponibles, se pasa el servicio de comunicación serial a cada una para que puedan usarlo
    final screens = [
      HomeScreen(
        serialService: widget.serialService,
        puertoArduino: widget.puertoArduino,
      ),
      AdminScreen(serialService: widget.serialService),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false, // quita el banner de debug en la esquina
      title: "CTB-UPM", // título de la app
      // Tema de la app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)), // esquema de colores basado en un color semilla
        useMaterial3: true, // habilita el uso de Material Design 3, que es la última versión del diseño de Google
      ),

      home: Scaffold(
        body: screens[index], // muestra la pantalla correspondiente al índice actual
        // ---------- Navbar ----------
        bottomNavigationBar: MainNavbar(
          currentIndex: index, // índice actual para resaltar el botón correspondiente
          onTap: (i) => setState(() => index = i), // actualiza el índice al hacer tap en un botón, lo que cambia la pantalla mostrada
        ),
      ),
    );
  }
}
