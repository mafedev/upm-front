import 'package:android_front_upm/services/serial_service.dart';
import 'package:flutter/material.dart';
import '../models/datos.dart';

class HomeScreen extends StatefulWidget {
  final SerialService serial;

  const HomeScreen({super.key, required this.serial});

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

    // pedir datos iniciales
    widget.serial.send("GET_SESIONES");
    widget.serial.send("GET_TOTAL");
    widget.serial.send("GET_SERIAL");
  }

  Widget card(String title, String value, String cmd) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => widget.serial.send(cmd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CTB-UPM")),
      body: Column(
        children: [
          card("Sesiones", "${datos.sesiones}", "GET_SESIONES"),
          card("Total", "${datos.total}", "GET_TOTAL"),
          card("Serial", datos.serial, "GET_SERIAL"),
        ],
      ),
    );
  }
}