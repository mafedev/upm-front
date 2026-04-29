import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/serial_service.dart';
import 'services/admin_service.dart';
import 'screens/home_screen.dart';
import 'screens/transfer_screen.dart';
import 'widgets/navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final serialService = SerialService();
  serialService.startAutoConnect();

  final adminService = AdminService(baseUrl: dotenv.env['BASE_URL']!);

  runApp(MyApp(serialService: serialService, adminService: adminService));
}

class MyApp extends StatelessWidget {
  final SerialService serialService;
  final AdminService adminService;

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
  final AdminService adminService;

  const MainScreen({
    super.key,
    required this.serialService,
    required this.adminService,
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
      TransferScreen(
        serialService: widget.serialService,
        api: widget.adminService,
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
