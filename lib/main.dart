import 'package:flutter/material.dart';
import 'services/serial_service.dart';
import 'screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(900, 900),
    minimumSize: Size(900, 650),
    center: true,
    title: "CTB-UPM",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  final SerialService serialService = SerialService();

  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CTB-UPM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF006D77), // azul médico
        ),
        scaffoldBackgroundColor: Color(0xFFF4F7F9),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF006D77),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0A9396),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final ports = serialService.getAvailablePorts();
          if (ports.isNotEmpty) serialService.open(ports.first);
          return HomeScreen(serialService: serialService);
        },
      ),
    );
  }
}
