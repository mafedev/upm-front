import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../models/datos.dart';

class HomeScreen extends StatefulWidget {
  final SerialService serialService;

  const HomeScreen({super.key, required this.serialService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Representa los datos recibidos del dispositivo, se actualizan cada vez que llega una nueva línea de datos por el puerto serie
  Datos datos = Datos.empty();

  @override
  void initState() {
    super.initState();

    // Al iniciar la pantalla, se suscribe al stream para escuchar los datos que llegan y así actualizar la interfaz
    widget.serialService.stream.listen((line) {
      setState(() {
        datos.updateFromString(line); // Actualiza según la línea que recibe
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card("Sesiones restantes", datos.sesiones.toString(), Icons.timer),
          _card("Total sesiones", datos.total.toString(), Icons.list_alt),
          _card("Número de serie", datos.serial, Icons.numbers),

          const SizedBox(height: 20),

          // ---------- Botón para leer sesiones restantes ----------
          ElevatedButton(
            onPressed: () => widget.serialService.send('2'),
            child: const Text("Leer sesiones"),
          ),

          // ---------- Botón para leer sesiones totales ----------
          ElevatedButton(
            onPressed: () => widget.serialService.send('5'),
            child: const Text("Leer sesiones totales"),
          ),

          // ---------- Botón para leer número de serie ----------
          ElevatedButton(
            onPressed: () => widget.serialService.send('3'),
            child: const Text("Leer número de serie"),
          ),

        ],
      ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
