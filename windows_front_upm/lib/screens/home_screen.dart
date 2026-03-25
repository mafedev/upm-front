import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../models/datos.dart';

class HomeScreen extends StatefulWidget {
  final SerialService serialService;
  final String puertoArduino; // puerto detectado para mostrar en la UI

  const HomeScreen({super.key, required this.serialService, required this.puertoArduino});

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
  // Si no se ha detectado ningún puerto, muestra un mensaje de error en la pantalla
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFE3F2FD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // ---------- Contenedor superior ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.white, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CTB-UPM",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      const Text("Sistema de control",
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 5),
                      Text("Puerto Arduino: ${widget.puertoArduino}",
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  // ---------- Cards con datos ----------
                  children: [
                    _dataRow(
                      title: "Sesiones restantes",
                      value: datos.sesionesStr,
                      icon: Icons.timer,
                      color: const Color(0xFF1E88E5),
                      command: '2',
                    ),
                    const SizedBox(height: 15),

                    _dataRow(
                      title: "Total sesiones",
                      value: datos.totalStr,
                      icon: Icons.list_alt,
                      color: const Color(0xFF2E7D32),
                      command: '5',
                    ),
                    const SizedBox(height: 15),

                    _dataRow(
                      title: "Número de serie",
                      value: datos.serial,
                      icon: Icons.qr_code,
                      color: const Color(0xFF0D47A1),
                      command: '3',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: lógica para cargar sesiones desde bdd
            },
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            label: const Text(
              "Cargar sesiones desde internet",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dataRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String command,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(width: 10),

          // Texto (ocupa todo el espacio posible)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // --------- BOTÓN ----------
          ElevatedButton(
            onPressed: () => widget.serialService.send(command),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
