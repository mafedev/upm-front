import 'package:android_front_upm/screens/reload_screen.dart';
import 'package:flutter/material.dart';
import 'services/serial_service.dart';
import 'screens/home_screen.dart';
import 'widgets/navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final serialService = SerialService();
  serialService.startAutoConnect();

  runApp(MyApp(serialService: serialService));
}

class MyApp extends StatelessWidget {
  final SerialService serialService;

  const MyApp({
    super.key,
    required this.serialService,
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
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final SerialService serialService;

  const MainScreen({
    super.key,
    required this.serialService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _arduinoConnected = false;

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
    final screens = [
      HomeScreen(
        serial: widget.serialService,
        arduinoConnected: _arduinoConnected,
      ),
      RechargeScreen(
        serialService: widget.serialService,
        arduinoConnected: _arduinoConnected,
      ),
    ];

    return Scaffold(
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
