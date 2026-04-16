import 'dart:async';
import 'package:flutter/material.dart';
import '../services/serial_service.dart';

class InputScreen extends StatefulWidget {
  final SerialService serialService;
  final int command;
  final String label;

  const InputScreen({
    super.key,
    required this.serialService,
    required this.command,
    required this.label,
  });

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<String>? _sub;
  bool _done = false;

  void _sendData() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    // Construir comando acorde al firmware del Arduino
    String cmd;
    if (widget.command == 1) {
      // Cargar sesiones
      cmd = 'SET_SESIONES:$input';
    } else if (widget.command == 4) {
      // Cambiar número de serie
      cmd = 'SET_SERIAL:$input';
    } else {
      // Por defecto enviamos el texto tal cual
      cmd = input;
    }

    widget.serialService.send(cmd);

    _sub = widget.serialService.dataStream.listen((line) {
      final l = line.trim().toUpperCase();
      if (l == 'OK' || l.startsWith('OK')) {
        _sub?.cancel();
        if (_done) return;
        _done = true;
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Dato enviado')));
          Navigator.pop(context);
        }
      } else if (l.startsWith('ERROR')) {
        _sub?.cancel();
        if (_done) return;
        _done = true;
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $line')));
        }
      }
    });

    // Fallback en 2 segundos: si no hay respuesta, asumimos enviado
    Future.delayed(const Duration(seconds: 2), () {
      if (_done) return;
      _done = true;
      _sub?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dato enviado (fallback)')));
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _controller),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendData,
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}