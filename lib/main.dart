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
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
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

  final serialService = SerialService();
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
  String puertoArduino = "Cargando…";
  bool _isScanning = false; // ⚡ flag para que no se abra el puerto varias veces
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPortScan();
  }

  // Buscar puerto Arduino
  String? _findArduinoPort(List<String> ports) {
    for (var p in ports) {
      final lower = p.toLowerCase();
      if (lower.contains("arduino") ||
          lower.contains("ch340") ||
          lower.contains("usb serial")) {
        return p.split(' - ').first.trim();
      }
    }
    return null;
  }

  // Escaneo seguro de puertos
  void _startPortScan() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isScanning) return; // ya hay un escaneo/abertura en curso
      _isScanning = true;

      final ports = widget.serialService.getAvailablePorts();

      if (ports.isEmpty) {
        if (puertoArduino != "Cargando…") {
          setState(() => puertoArduino = "Cargando…");
        }
        _isScanning = false;
        return;
      }

      final arduinoPort = _findArduinoPort(ports);
      final port = arduinoPort ?? ports.first.split(' - ').first.trim();

      if (puertoArduino != port || widget.serialService.isConnected != true) {
        debugPrint("🔄 Intentando abrir puerto $port...");

        // Delay de 2s antes de abrir (Windows)
        await Future.delayed(const Duration(seconds: 2));

        final success = await widget.serialService.open(port);

        if (success) {
          debugPrint("✅ Puerto abierto correctamente: $port");
          if (mounted) {
            setState(() => puertoArduino = port);
          }
        } else {
          debugPrint("❌ No se pudo abrir el puerto $port");
          if (mounted) {
            setState(() => puertoArduino = "Error al abrir puerto");
          }
        }
      }

      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      debugShowCheckedModeBanner: false,
      title: "CTB-UPM",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack(index: index, children: screens),
        bottomNavigationBar: MainNavbar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
        ),
      ),
    );
  }
}