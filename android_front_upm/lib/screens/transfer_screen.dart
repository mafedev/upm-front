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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SystemAppBar(
          subtitle: widget.serialService.isConnected
              ? "Arduino Conectado"
              : "No conectado",
          showLogout: false,
          onLogout: null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: loading ? null : _loadData,
              tooltip: 'Refrescar',
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Serial Arduino:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(arduinoSerial ?? "No detectado"),

                  const SizedBox(height: 20),

                  Text(
                    "Sesiones en Arduino:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("$current"),

                  const SizedBox(height: 20),

                  Text(
                    "Sesiones pendientes:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("$pending"),

                  const SizedBox(height: 20),

                  Text(
                    "Total después de transferir:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("${current + pending}"),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _transfer,
                      child: const Text("TRANSFERIR"),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
