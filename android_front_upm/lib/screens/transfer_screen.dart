import 'package:android_front_upm/services/session_service.dart';
import 'package:android_front_upm/widgets/buttons/primary_button.dart';
import 'package:android_front_upm/widgets/cards/app_stat_card.dart';
import 'package:android_front_upm/widgets/cards/info_box.dart';
import 'package:android_front_upm/widgets/row_item.dart';
import 'package:flutter/material.dart';
import 'package:android_front_upm/widgets/appbar.dart';
import '../services/serial_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TransferScreen extends StatefulWidget {
  final SerialService serialService; // Maneja la comunicación serial con el dispositivo
  final SessionService sessionService; // Maneja las sesiones en el backend

  const TransferScreen({
    super.key,
    required this.serialService,
    required this.sessionService,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  bool loading = false;
  String? arduinoSerial;
  int pending = 0; // Sesiones pendientes en el backend
  int current = 0; // Sesiones actualmente en el dispositivo

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Carga los datos iniciales del dispositivo y el backend ----------
  Future<void> _loadData() async {
    try {
      setState(() => loading = true);

      final serial = await widget.serialService.getSerial(); // Obtiene el número serial del dispositivo conectado
      final exists = await widget.sessionService.deviceExists(serial); // Verifica si el dispositivo está registrado en el backend

      arduinoSerial = serial; // Actualiza el número serial en el estado

      // Si el dispositivo no existe en el backend, muestra un mensaje de error y resetea los contadores
      if (!exists) {
        _show("Dispositivo no registrado: $serial");
        setState(() {
          pending = 0;
          current = 0;
        });
        return;
      }

      final backendPending = await widget.sessionService.getPendingSessions(serial); // Obtiene el número de sesiones pendientes en el backend
      final arduinoSessions = await widget.serialService.getSessions(); // Obtiene el número de sesiones en el dispositivo

      // Actualiza el estado con los datos obtenidos
      setState(() {
        pending = backendPending;
        current = arduinoSessions;
      });
    } catch (e) {
      _show("Error cargando datos");
    } finally {
      setState(() => loading = false);
    }
  }

  // ---------- Realiza la transferencia de sesiones entre el backend y el dispositivo ----------
  Future<void> _transfer() async {
    if (arduinoSerial == null) return;

    try {
      setState(() => loading = true);

      final exists = await widget.sessionService.deviceExists(arduinoSerial!); // Verifica nuevamente si el dispositivo existe en el backend antes de transferir
      if (!exists) {
        _show("Dispositivo no válido"); // si el dispositivo no existe, muestra un mensaje de error y detiene la transferencia
        return;
      }

      // Obtiene el número de sesiones pendientes en el backend para el dispositivo conectado
      final backendPending = await widget.sessionService.getPendingSessions(
        arduinoSerial!,
      );

      // Si no hay sesiones pendientes en el backend, muestra un mensaje y detiene la transferencia
      if (backendPending <= 0) {
        _show("No hay sesiones pendientes");
        return;
      }

      final arduinoCurrent = await widget.serialService.getSessions(); // Obtiene el número de sesiones actualmente en el dispositivo

      // Calcula el total de sesiones que se transferirán sumando las sesiones pendientes en el backend y las sesiones actuales en el dispositivo
      final total = backendPending + arduinoCurrent;

      await widget.serialService.loadSessions(total);
      await widget.sessionService.confirmTransfer(arduinoSerial!);

      _show("Transferido correctamente: $total");
      await _loadData();
    } catch (e) {
      _show("Error en transferencia");
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
    final total = current + pending;
    final isConnected = widget.serialService.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SystemAppBar(
          subtitle: "Transferencia de sesiones",
          isConnected: isConnected,
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
                  AppInfoBanner(
                    text:
                        "Antes de continuar, verifica que el dispositivo esté correctamente conectado y que tengas una buena conexión a internet.",
                    icon: Icons.info_outline,
                    color: AppColors.danger,
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
                        AppRowItem(
                          label: "Número serial",
                          value: arduinoSerial ?? "No detectado",
                          icon: Icons.memory,
                        ),
                        AppRowItem(
                          label: "Sesiones en dispositivo",
                          value: "$current",
                          icon: Icons.usb,
                        ),
                        AppRowItem(
                          label: "Sesiones a cargar",
                          value: "$pending",
                          icon: Icons.cloud,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Resultado de la transferencia",
                    style: AppTextStyles.headingSmall,
                  ),

                  const SizedBox(height: 10),

                  AppStatCard(
                    title: "Total final",
                    value: "$total",
                    icon: Icons.bar_chart,
                    color: AppColors.primary,
                  ),

                  const Spacer(),

                  PrimaryButton(
                    text: "TRANSFERIR",
                    loading: loading,
                    onPressed: _transfer,
                  ),
                ],
              ),
            ),
    );
  }
}
