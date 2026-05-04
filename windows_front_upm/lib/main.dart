import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';

import 'services/admin_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1100, 750), // tamaño inicial de la ventana
      minimumSize: Size(1000, 700), // tamaño mínimo de la ventana
      center: true, // centra la ventana en la pantalla
      title: "CTB-UPM", // título de la ventana
    );

    // Espera a que la ventana esté lista para mostrarse, luego la muestra y le da el foco
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show(); // muestra la ventana
      await windowManager.focus(); // le da el foco a la ventana
    });
  }

  final adminService = AdminService(
    baseUrl: dotenv.env['BASE_URL']!,
    token: dotenv.env['API_TOKEN']!,
  );

  runApp(MyApp(adminService: adminService));
}

class MyApp extends StatelessWidget {
  final AdminService adminService;

  const MyApp({super.key, required this.adminService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminDashboardScreen(api: adminService),
    );
  }
}
