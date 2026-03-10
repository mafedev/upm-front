import 'package:flutter/material.dart';
import 'services/serial_service.dart';
import 'screens/home_screen.dart';

void main() {
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
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
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