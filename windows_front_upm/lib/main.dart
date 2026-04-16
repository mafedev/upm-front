import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_front_upm/services/serial_windows.dart';
import 'services/session_service.dart';
import 'services/serial_service.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'widgets/navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // -------- CONFIG WINDOWS --------
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(900, 700),
      minimumSize: Size(900, 650),
      center: true,
      title: "CTB-UPM",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // -------- SERVICES --------
  final serialService = WindowsSerialService();
  serialService.startAutoConnect(); // inicia la auto-conexión

  final sessionService = SessionService();

  runApp(
    MainApp(
      serialService: serialService,
      sessionService: sessionService,
    ),
  );
}

class MainApp extends StatefulWidget {
  final SerialService serialService;
  final SessionService sessionService;

  const MainApp({
    super.key,
    required this.serialService,
    required this.sessionService,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int index = 0;
  bool arduinoConnected = false;

  @override
  void initState() {
    super.initState();

    // Escucha estado de conexión
    widget.serialService.connectionStream.listen((connected) {
      setState(() {
        arduinoConnected = connected;
      });
      // Al conectarnos, pedimos el estado actual al Arduino
      if (connected) {
        widget.serialService.send('GET_SESIONES');
        widget.serialService.send('GET_TOTAL');
        widget.serialService.send('GET_SERIAL');
        widget.serialService.send('GET_ESTADO');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        serialService: widget.serialService,
        arduinoConnected: arduinoConnected,
      ),
      AdminScreen(
        serialService: widget.serialService,
        sessionService: widget.sessionService,
        arduinoConnected: arduinoConnected,
      ),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CTB-UPM",
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: index,
          children: screens,
        ),
        bottomNavigationBar: MainNavbar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.serialService.dispose();
    super.dispose();
  }
}