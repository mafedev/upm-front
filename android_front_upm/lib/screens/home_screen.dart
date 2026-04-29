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
  String serialNumber = "-";

  bool _connecting = false;
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

  Widget _dataCard(
    String title,
    String value,
    VoidCallback onRefresh,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),

                _dataCard(
                  "Sesiones restantes",
                  sesiones.toString(),
                  _loadData,
                  const Color(0xFF1E88E5),
                  Icons.timer,
                ),

                _dataCard(
                  "Total sesiones",
                  total.toString(),
                  _loadData,
                  const Color(0xFF2E7D32),
                  Icons.list_alt,
                ),

                _dataCard(
                  "Número de serie",
                  serialNumber,
                  _loadData,
                  const Color(0xFF0D47A1),
                  Icons.qr_code,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
