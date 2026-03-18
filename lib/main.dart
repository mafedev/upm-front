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
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final serialService = SerialService();
  final sessionService = SessionService();

  runApp(MainApp(
    serialService: serialService,
    sessionService: sessionService,
  ));
}

class MainApp extends StatefulWidget {
  final SerialService serialService;
  final SessionService sessionService;

  const MainApp({super.key, required this.serialService, required this.sessionService});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int index = 0;
  String puertoArduino = "Buscando...";

  @override
  void initState() {
    super.initState();

    // Escucha el stream de cambios de puerto
    widget.serialService.portStream.listen((port) {
      setState(() {
        puertoArduino = port ?? "Buscando...";
      });
    });
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