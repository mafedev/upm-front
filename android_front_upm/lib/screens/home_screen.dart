import 'package:android_front_upm/widgets/appbar.dart';
import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../models/datos.dart';

class HomeScreen extends StatefulWidget {
  final SerialService serial;
  final bool arduinoConnected;

  const HomeScreen({
    super.key,
    required this.serial,
    this.arduinoConnected = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final datos = Datos();

  @override
  void initState() {
    super.initState();
    widget.serial.dataStream.listen((line) {
      setState(() {
        datos.updateFromLine(line);
      });
    });

    // Pedir datos iniciales
    widget.serial.send("GET_SESIONES");
    widget.serial.send("GET_TOTAL");
    widget.serial.send("GET_SERIAL");
  }

  Widget _dataCard(
    String title,
    String value,
    String cmd,
    Color color,
    IconData icon,
  ) {
    final displayValue = (value.isEmpty || value == "0") ? "-" : value;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(displayValue, style: const TextStyle(fontSize: 16)),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => widget.serial.send(cmd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SystemAppBar(
          subtitle: widget.arduinoConnected
              ? "Arduino Conectado"
              : "No conectado",
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _dataCard(
                  "Sesiones restantes",
                  datos.sesiones.toString(),
                  "GET_SESIONES",
                  const Color(0xFF1E88E5),
                  Icons.timer,
                ),
                _dataCard(
                  "Total sesiones",
                  datos.total.toString(),
                  "GET_TOTAL",
                  const Color(0xFF2E7D32),
                  Icons.list_alt,
                ),
                _dataCard(
                  "Número de serie",
                  datos.serial,
                  "GET_SERIAL",
                  const Color(0xFF0D47A1),
                  Icons.qr_code,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
