import 'package:flutter/material.dart';
import 'package:android_front_upm/widgets/appbar.dart';
import '../services/serial_service.dart';

class RechargeScreen extends StatefulWidget {
  final SerialService serialService;
  final bool arduinoConnected;

  const RechargeScreen({
    super.key,
    required this.serialService,
    required this.arduinoConnected,
  });

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SystemAppBar(subtitle: widget.arduinoConnected ? 'Arduino Conectado' : 'No conectado'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Recargar Arduino',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Recargar sesiones al Arduino'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
