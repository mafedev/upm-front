import 'dart:async';

import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../models/datos.dart';

class HomeScreen extends StatefulWidget {
  final SerialService serialService;
  final bool arduinoConnected;

  const HomeScreen({
    super.key,
    required this.serialService,
    required this.arduinoConnected,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Datos datos = Datos.empty();
  late final StreamSubscription<String> _sub;

  @override
  void initState() {
    super.initState();

    // Suscribirse al stream de datos entrantes
    _sub = widget.serialService.dataStream.listen((line) {
      setState(() {
        datos.updateFromString(line);
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.arduinoConnected
                  ? 'Arduino Conectado'
                  : 'Arduino no conectado',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text('Sesiones restantes: ${datos.sesionesStr}'),
            Text('Total sesiones: ${datos.totalStr}'),
            Text('Serial: ${datos.serial}'),
          ],
        ),
      ),
    );
  }
}