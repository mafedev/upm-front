import 'package:android_front_upm/widgets/appbar.dart';
import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../services/admin_service.dart';

class TransferScreen extends StatefulWidget {
  final SerialService serialService;
  final AdminService api;

  const TransferScreen({
    super.key,
    required this.serialService,
    required this.api,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  bool loading = false;
  String? arduinoSerial;
  int pending = 0;
  int current = 0;

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadData() async {
    try {
      setState(() => loading = true);

      final serial = await widget.serialService.getSerial();
      final exists = await widget.api.deviceExists(serial);

      if (!exists) {
        _show("Dispositivo no registrado: $serial");
        setState(() {
          arduinoSerial = serial;
          pending = 0;
          current = 0;
        });
        return;
      }

      final backendPending = await widget.api.getPendingSessions(serial);
      final arduinoSessions = await widget.serialService.getSessions();

      setState(() {
        arduinoSerial = serial;
        pending = backendPending;
        current = arduinoSessions;
      });
    } catch (e) {
      _show("Error cargando datos: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _transfer() async {
    if (arduinoSerial == null) return;

    try {
      setState(() => loading = true);

      final exists = await widget.api.deviceExists(arduinoSerial!);
      if (!exists) {
        _show("Dispositivo no válido");
        return;
      }

      final backendPending = await widget.api.getPendingSessions(
        arduinoSerial!,
      );

      if (backendPending <= 0) {
        _show("No hay sesiones pendientes");
        return;
      }

      final arduinoCurrent = await widget.serialService.getSessions();

      final total = backendPending + arduinoCurrent;

      await widget.serialService.loadSessions(total);

      await widget.api.confirmTransfer(arduinoSerial!);

      _show("Transferido correctamente: $total");
      await _loadData();
    } catch (e) {
      _show("Error en transferencia: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _rowItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = current + pending;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SystemAppBar(
          subtitle: widget.serialService.isConnected
              ? "Dispositivo Conectado"
              : "No conectado",
          showLogout: false,
          onLogout: null,
          actions: [
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              onPressed: loading ? null : _loadData,
            ),
          ],
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Transferencia de sesiones al dispositivo.\nAntes de continuar, verifica que el dispositivo esté correctamente conectado.",
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Estado actual",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _rowItem(
                          "Número serial",
                          arduinoSerial ?? "No detectado",
                          Icons.memory,
                        ),
                        _rowItem("Sesiones en dispositivo", "$current", Icons.usb),
                        _rowItem(
                          "Sesiones a cargar",
                          "$pending",
                          Icons.cloud,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Resultado de la transferencia",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total final",
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$total",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : _transfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "TRANSFERIR",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
