import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/serial_service.dart';

class InputScreen extends StatefulWidget {
  final SerialService serialService;
  final int command;
  final String label;

  const InputScreen({super.key, required this.serialService, required this.command, required this.label});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<String>? _sub;

  // ---------- Enviar datos al Arduino ----------
  void _sendData() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    // envía el comando principal
    await widget.serialService.send(widget.command.toString());

    // suscribirse al stream para esperar la respuesta
    _sub = widget.serialService.stream.listen((line) async {
      final l = line.toLowerCase();
      if (l.contains('introduce')) {
        await widget.serialService.send(input, terminator: '\r\n'); // envía el valor al Arduino
        _sub?.cancel();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dato enviado')));
          Navigator.pop(context);
        }
      }
    });

    // Fallback: si en 2 segundos no hay respuesta, enviar de todas formas
    Future.delayed(const Duration(seconds: 2), () async {
      if (_sub != null) {
        await widget.serialService.send(input, terminator: '\r\n');
        _sub?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Dato enviado (fallback)')));
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        title: Row(
          children: const [
            Icon(Icons.medical_services, size: 32),
            SizedBox(width: 10),
            Text("CTB-UPM"),
          ],
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendData,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'Enviar',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }
}