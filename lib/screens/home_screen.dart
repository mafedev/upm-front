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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF1F8E9)],
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
                children: [
                  // ---------- Cards con datos ----------
                  Row(
                    children: [
                      Expanded(
                        child: _statCard("Sesiones restantes", datos.sesionesStr, Icons.timer, const Color(0xFF1E88E5)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _statCard("Total sesiones", datos.totalStr, Icons.list_alt, const Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _statCard("Número de serie", datos.serial, Icons.qr_code, const Color(0xFF0D47A1)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ---------- Botones ----------
                  Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: [
                      _actionButton("Leer sesiones", Icons.refresh, const Color(0xFF1E88E5), '2'), 
                      _actionButton("Leer sesiones totales", Icons.analytics, const Color(0xFF2E7D32), '5'),
                      _actionButton("Leer número de serie", Icons.badge, const Color(0xFF0D47A1), '3'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, String command) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => widget.serialService.send(command),
      ),
    );
  }
}