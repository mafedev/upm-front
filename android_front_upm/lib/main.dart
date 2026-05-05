import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/serial_service.dart';
import 'services/session_service.dart';
import 'screens/home_screen.dart';
import 'screens/transfer_screen.dart';
import 'widgets/navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // Carga las variables de entorno

  final serialService = SerialService();
  serialService.startAutoConnect(); // Inicia la conexión automática al Arduino

  final adminService = SessionService(baseUrl: dotenv.env['BASE_URL']!); // Usa la URL del backend desde las variables de entorno

  runApp(MyApp(serialService: serialService, adminService: adminService));
}

class MyApp extends StatelessWidget {
  final SerialService serialService;
  final SessionService adminService;

  const MyApp({
    super.key,
    required this.serialService,
    required this.adminService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CTB-UPM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
      ),
      home: MainScreen(
        serialService: serialService,
        adminService: adminService,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final SerialService serialService;
  final SessionService adminService;

  const MainScreen({
    super.key,
    required this.serialService,
    required this.adminService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Índice para controlar la pantalla actual
  bool _arduinoConnected = false; // Estado de conexión con el Arduino

  @override
  void initState() {
    super.initState();
    widget.serialService.connectionStream.listen((connected) {
      setState(() {
        _arduinoConnected = connected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas
    final screens = [
      HomeScreen(
        serial: widget.serialService,
        arduinoConnected: _arduinoConnected,
      ),
      TransferScreen(
        serialService: widget.serialService,
        sessionService: widget.adminService,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: MainNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.serialService.dispose();
    super.dispose();
  }
}
