import 'package:android_front_upm/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'services/serial_service.dart';
import 'services/session_service.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final serialService = SerialService();
  serialService.startAutoConnect();

  final sessionService = SessionService();

  runApp(MyApp(
    serialService: serialService,
    sessionService: sessionService,
  ));
}

class MyApp extends StatelessWidget {
  final SerialService serialService;
  final SessionService sessionService;

  const MyApp({
    super.key,
    required this.serialService,
    required this.sessionService,
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
        sessionService: sessionService,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final SerialService serialService;
  final SessionService sessionService;

  const MainScreen({
    super.key,
    required this.serialService,
    required this.sessionService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String puerto = "Desconectado";

  @override
  void initState() {
    super.initState();

    widget.serialService.connectionStream.listen((connected) {
      setState(() {
        puerto = connected ? "Arduino Conectado" : "No conectado";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas, según el índice actual
    final screens = [
      HomeScreen(serial: widget.serialService),
      AdminScreen(
        serialService: widget.serialService,
        sessionService: widget.sessionService,
        puertoArduino: puerto,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("CTB-UPM ($puerto)"),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: MainNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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