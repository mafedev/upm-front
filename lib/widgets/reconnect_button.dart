import 'package:flutter/material.dart';
import '../services/serial_service.dart';

class ReconnectButton extends StatefulWidget {
  final SerialService serialService;
  final String puertoArduino;

  const ReconnectButton({
    super.key,
    required this.serialService,
    required this.puertoArduino,
  });

  @override
  State<ReconnectButton> createState() => _ReconnectButtonState();
}

class _ReconnectButtonState extends State<ReconnectButton> {
  bool _isConnecting = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos el estado de conexión según si ya hay puerto abierto
    _connected = widget.serialService != null && widget.puertoArduino.isNotEmpty;
  }

  Future<void> _reconnect() async {
    if (_isConnecting || widget.puertoArduino.isEmpty) return;

    setState(() {
      _isConnecting = true;
    });

    debugPrint("🔄 Intentando reconectar al puerto ${widget.puertoArduino}...");

    final success = await widget.serialService.reconnect(widget.puertoArduino);

    setState(() {
      _isConnecting = false;
      _connected = success;
    });

    debugPrint(success
        ? "✅ Reconectado correctamente a ${widget.puertoArduino}"
        : "❌ No se pudo reconectar a ${widget.puertoArduino}");
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _reconnect,
      icon: Icon(
        _connected
            ? Icons.usb  // conectado
            : Icons.usb_off, // desconectado
        color: Colors.white,
      ),
      label: _isConnecting
          ? const Text("Conectando…")
          : Text(_connected ? "Conectado" : "Desconectado"),
      style: ElevatedButton.styleFrom(
        backgroundColor: _connected ? Colors.green : Colors.red,
      ),
    );
  }
}