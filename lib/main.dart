import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'services/serial_service.dart';
import 'services/session_service.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'widgets/navbar.dart';
import 'package:usb_serial/usb_serial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de la ventana para Windows
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

  // Detectar automáticamente Arduino y abrir puerto
  String puertoDetectado = "No detectado";
  final devices = await serialService.getAvailableDevices();

  if (devices.isNotEmpty) {
    // Se toma el primer dispositivo USB
    final device = devices.first;
    puertoDetectado = device.productName ?? "Arduino";
    bool opened = await serialService.open(device);
    if (!opened) {
      debugPrint("No se pudo abrir el puerto del dispositivo $puertoDetectado");
      puertoDetectado = "Error al abrir";
    }
  }

  runApp(MainApp(
    serialService: serialService,
    sessionService: sessionService,
    puertoArduino: puertoDetectado,
  ));
}

class MainApp extends StatefulWidget {
  final SerialService serialService;
  final SessionService sessionService;
  final String puertoArduino;

  const MainApp({
    super.key,
    required this.serialService,
    required this.sessionService,
    required this.puertoArduino,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        serialService: widget.serialService,
        puertoArduino: widget.puertoArduino,
      ),
      AdminScreen(
        serialService: widget.serialService,
        sessionService: widget.sessionService,
        puertoArduino: widget.puertoArduino,
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