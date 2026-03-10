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

  void _sendData() {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    // Enviar comando primero
    widget.serialService.send(widget.command.toString());

    // Escuchar prompt del Arduino y enviar el dato cuando aparezca
    _sub = widget.serialService.stream.listen((line) {
      final l = line.toLowerCase();
      if (l.contains('introduce numero') ||
          l.contains('introduzca numero') ||
          l.contains('introduce')) {
        widget.serialService.sendWithTerminator(input, terminator: '\r\n');
        _sub?.cancel();
        _sub = null;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Dato enviado')));
          Navigator.pop(context);
        }
      }
    });

    // Fallback: si no llega el prompt en 2s, enviar de todas formas
    Future.delayed(Duration(seconds: 2), () {
      if (_sub != null) {
        widget.serialService.sendWithTerminator(input, terminator: '\r\n');
        _sub?.cancel();
        _sub = null;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Dato enviado (fallback)')));
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.label,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sendData,
              icon: Icon(Icons.send),
              label: Text('Enviar', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
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
