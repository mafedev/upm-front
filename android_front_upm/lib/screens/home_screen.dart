import 'package:android_front_upm/widgets/appbar.dart';
import 'package:flutter/material.dart';
import '../services/serial_service.dart';

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
  int sesiones = 0;
  int total = 0;
  String serialNumber = "0";

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!widget.serial.isConnected) return;

    setState(() => _loading = true);

    try {
      final s = await widget.serial.getSessions();
      final t = await widget.serial.getTotalSessions();
      final sn = await widget.serial.getSerial();

      setState(() {
        sesiones = s;
        total = t;
        serialNumber = sn;
      });
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _dataCard({
    required String title,
    required String value,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "VER",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SystemAppBar(
          subtitle: widget.serial.isConnected
              ? "Arduino Conectado"
              : "No conectado",
          showLogout: false,
          onLogout: null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
              tooltip: 'Refrescar',
            ),
          ],
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F7FB),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      _dataCard(
                        title: "Sesiones restantes",
                        value: sesiones.toString(),
                        onTap: _loadData,
                        color: const Color(0xFF2563EB),
                        icon: Icons.timer_outlined,
                      ),

                      _dataCard(
                        title: "Total sesiones",
                        value: total.toString(),
                        onTap: _loadData,
                        color: const Color(0xFF16A34A),
                        icon: Icons.stacked_bar_chart_outlined,
                      ),

                      _dataCard(
                        title: "Número de serie",
                        value: serialNumber,
                        onTap: _loadData,
                        color: const Color(0xFF7C3AED),
                        icon: Icons.qr_code_2_outlined,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
