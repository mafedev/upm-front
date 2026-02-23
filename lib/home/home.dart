import 'package:flutter/material.dart';
import '../services/serial_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SerialService _serial = SerialService();
  String _response = "Sin respuesta";

  @override
  void initState() {
    super.initState();

    bool opened = _serial.open("COM5");

    print("Puerto abierto: $opened");

    if (opened) {
      _serial.stream.listen((data) {
        print("Recibido: $data");
        setState(() {
          _response = data;
        });
      });
    }
  }

  @override
  void dispose() {
    _serial.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arduino Menu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _response,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _serial.send("0"),
              child: const Text("Leer sesiones"),
            ),
          ],
        ),
      ),
    );
  }
}