import 'package:flutter/material.dart';
import '../services/serial_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SerialService _serial = SerialService(); // Instancia del servicio
  String _response = "Sin respuesta"; // Es el texto que se muestra al presionar el botón, por defecto es "sin respuesta"

  @override
  void initState() {
    super.initState();

    // Se abre el puerto usando el método del servicio, le pasa por parámetro el puerto
    bool opened = _serial.open("COM5");
    debugPrint("Puerto abierto: $opened"); // Debug para saber si se abrió el puerto

    // Si se abrió sin problemas, escucha los datos que le llegan
    if (opened) {
      _serial.stream.listen((data) {
        debugPrint("Recibido: $data"); // Debug para saber que datos llegaron
        setState(() {
          _response = data; // Actualiza la interfaz mostrando lo que recibió
        });
      });
    }
  }

  @override
  void dispose() {
    _serial.close(); // Cierra el puerto
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arduino Menu")),
      body: Padding(
        padding: const EdgeInsets.all(20), // espaciado interno
        child: Column(
          children: [
            Text(
              _response, // Datos que le llegaron
              style: const TextStyle(fontSize: 18)
            ),
            const SizedBox(height: 30),

            // ---------- Ver sesiones ----------
            ElevatedButton(
              onPressed: () => _serial.send("0"), // Al presionar el botón envía un '0' al Arduino
              child: const Text("Sesiones disponibles"),
            ),

            const SizedBox(height: 15),

            // ---------- Ver número de serie ----------
            ElevatedButton(
              onPressed: () =>_serial.send("1"), // Al presionar el botón envia un '1' al Arduino
            child: const Text("Número de serie"))
          ],
        ),
      ),
    );
  }
}
