import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/serial_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de ventana en Windows
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(900, 850),
      minimumSize: Size(900, 650),
      center: true,
      title: "CTB-UPM",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final SerialService serialService = SerialService();
  bool _portOpened = false;

  @override
  void initState() {
    super.initState();
    _initSerialPort();
  }

  void _initSerialPort() {
    final ports = serialService.getAvailablePorts();
    debugPrint('Puertos detectados: $ports');

    if (ports.isEmpty) {
      _showError('No se detectaron puertos seriales disponibles.');
      return;
    }

    // Extrae solo COMx en Windows o el nombre adecuado en Android
    String portName = ports.first.split(' - ').first.trim();

    bool ok = serialService.open(portName);
    if (!ok) {
      _showError('No se pudo abrir el puerto $portName.\n'
          'Verifica que no esté siendo usado por otro programa.');
    } else {
      setState(() => _portOpened = true);
    }
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error de puerto serial'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    serialService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CTB-UPM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF006D77)),
      ),
      home: HomeScreen(serialService: serialService),
    );
  }
}