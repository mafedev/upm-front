import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'services/serial_service.dart';
import 'services/session_service.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'widgets/navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Se encarga de inicializar los bindings de Flutter

  // Configuración de la ventana para Windows
  // Es necesario porque de lo contrario al cambiar el tamaño de la ventana se recarga toda la app y la app se rompe

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    // verifica que no esté en web y que el sistema operativo sea Windows
    await windowManager
        .ensureInitialized(); // inicializa el window manager, es el encargado de manejar la ventana en Windows

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
  // Se encarga de manejar la sesión, para que si se cambia de pestaña, no se cierre la sesión
  final sessionService = SessionService();

  runApp(
    MainApp(
      serialService: serialService, // pasa el servicio
      sessionService: sessionService, // pasa el servicio de sesión
    ),
  );
}

class MainApp extends StatefulWidget {
  final SerialService serialService; // comunicación con el arduino
  final SessionService sessionService; // manejo de sesión

  const MainApp({
    super.key,
    required this.serialService,
    required this.sessionService,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int index = 0; // índice para controlar la pantalla actual, 0 para HomeScreen y 1 para AdminScreen

  String puertoArduino = "Cargando…"; // variable para mostrar el puerto detectado en la UI, inicialmente muestra "Cargando…" hasta que se detecte un puerto disponible
  Timer? _timer; // timer para escanear los puertos disponibles cada cierto tiempo, se cancela al cerrar la app para evitar fugas de memoria

  @override
  void initState() {
    super.initState();

    _startPortScan();
  }

  // ---------- Función para encontrar el puerto del Arduino ---------
  String? _findArduinoPort(List<String> ports) {
    // Busca en la lista de puertos disponibles alguno que contenga palabras clave relacionadas con Arduino, como "arduino", "ch340" o "usb serial"
    for (var p in ports) {
      final lower = p.toLowerCase();

      // Si encuentra un puerto que contenga alguna de estas palabras, devuelve el nombre del puerto
      if (lower.contains("arduino") ||
          lower.contains("ch340") ||
          lower.contains("usb serial")) {
        return p.split(' - ').first.trim();
      }
    }
    return null;
  }

  // ---------- Escaneo de puertos disponibles ---------
  void _startPortScan() {
    // cada 2 segundos, escanea los puertos disponibles usando el servicio de comunicación serial
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      final ports = widget.serialService.getAvailablePorts();

      // Si no se detecta ningún puerto, muestra "Cargando…"
      if (ports.isEmpty) {
        if (puertoArduino != "Cargando…") {
          setState(() {
            puertoArduino = "Cargando…";
          });
        }
        return;
      }

      // Si se detecta algún puerto, intenta encontrar el puerto del Arduino usando la función _findArduinoPort
      final arduinoPort = _findArduinoPort(ports);
    
      // Si no se encuentra un puerto que parezca ser el del Arduino, toma el primer puerto disponible
      final port = arduinoPort ?? ports.first.split(' - ').first.trim();

      // Si el puerto detectado es diferente al que ya se ha abierto, abre el nuevo puerto y actualiza la variable para mostrarlo
      if (puertoArduino != port) {
        widget.serialService.open(port);

        setState(() {
          puertoArduino = port;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Lista de pantallas disponibles, se pasa el servicio de comunicación serial a cada una para que puedan usarlo
    final screens = [
      HomeScreen(
        serialService: widget.serialService,
        puertoArduino: puertoArduino,
      ),

      AdminScreen(
        serialService: widget.serialService,
        sessionService: widget.sessionService,
        puertoArduino: puertoArduino,
      ),
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
        
        // IndexedStack es un widget que muestra solo un hijo a la vez, pero mantiene el estado de todos los hijos, lo que es útil para mantener la sesión iniciada al cambiar de pantalla
        body: IndexedStack(index: index, children: screens),

        // ---------- Navbar ----------
        bottomNavigationBar: MainNavbar(
          currentIndex: index, // índice actual para resaltar el botón correspondiente
          onTap: (i) => setState(() => index = i), // actualiza el índice al hacer tap en un botón, lo que cambia la pantalla mostrada
        ),
      ),
    );
  }
}
