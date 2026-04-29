import 'package:flutter/material.dart';
import 'package:android_front_upm/widgets/appbar.dart';
import '../services/serial_service.dart';
import '../services/admin_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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

      arduinoSerial = serial;

      if (!exists) {
        _show("Dispositivo no registrado: $serial");
        setState(() {
          pending = 0;
          current = 0;
        });
        return;
      }

      final backendPending = await widget.api.getPendingSessions(serial);
      final arduinoSessions = await widget.serialService.getSessions();

      setState(() {
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
          Icon(icon, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = current + pending;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SystemAppBar(
          subtitle: "Transferencia de sesiones",
          isConnected: widget.serialService.isConnected,
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
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.danger),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Antes de continuar, verifica que el dispositivo esté correctamente conectado y que tengas una buena conexión a internet.",
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text("Estado actual", style: AppTextStyles.headingSmall),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _rowItem(
                          "Número serial",
                          arduinoSerial ?? "No detectado",
                          Icons.memory,
                        ),
                        _rowItem(
                          "Sesiones en dispositivo",
                          "$current",
                          Icons.usb,
                        ),
                        _rowItem("Sesiones a cargar", "$pending", Icons.cloud),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Resultado de la transferencia",
                    style: AppTextStyles.headingSmall,
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.infoBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total final",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("$total", style: AppTextStyles.headingLarge),
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
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "TRANSFERIR",
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
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
