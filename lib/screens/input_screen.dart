import 'dart:async';
import 'package:flutter/material.dart';
import '../services/serial_service.dart';

class InputScreen extends StatefulWidget {
  final SerialService serialService; // servicio de comunicación
  final int command; // comando que se enviará al arduino
  final String label; // etiqueta para mostrar en el TextField

  const InputScreen({super.key, required this.serialService, required this.command, required this.label});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _controller = TextEditingController(); // controlador para el TextField, para poder obtener el valor ingresado por el usuario
  StreamSubscription<String>? _sub; // suscripción al stream de la comunicación serial, para escuchar la respuesta del arduino después de enviar el comando con el valor ingresado por el usuario

  // ---------- Enviar datos al arduino ----------
  void _sendData() {
    String input = _controller.text.trim(); // obtiene el valor ingresado por el usuario y le quita los espacios en blanco
    if (input.isEmpty) return; // si el valor está vacío, no hace nada

    // envía el comando
    widget.serialService.send(widget.command.toString());

    // se suscribe al stream de la comunicación serial para escuchar la respuesta del arduino
    _sub = widget.serialService.stream.listen((line) {
      final l = line.toLowerCase(); // convierte la línea a minúsculas
      
      if (l.contains('introduce')) { // si la línea contiene la palabra "introduce", significa que el arduino está listo para recibir el valor
        widget.serialService.send(input, terminator: '\r\n'); // envía el valor ingresado por el usuario al arduino, con un salto de línea al final para indicar que es el final del comando
        _sub?.cancel(); // cancela la suscripción al stream, ya que no se necesita escuchar más respuestas del arduino después de enviar el valor
        
        // si salío bien, muestra un mensaje y vuelve a la pantalla anterior
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dato enviado')));
          Navigator.pop(context);
        }
      }
    });

    // Si después de 2 segundos no se ha recibido la respuesta del arduino, se asume que hubo un error y se envía el valor de todas formas (esto es un fallback por si el arduino no responde correctamente, para evitar que el usuario se quede atascado en esta pantalla sin poder enviar el comando)
    Future.delayed(const Duration(seconds: 2), () {
      // Si la suscripción al stream todavía está activa, significa que no se ha recibido la respuesta del arduino, por lo que se envía el valor de todas formas como fallback
      if (_sub != null) {
        widget.serialService.send(input, terminator: '\r\n'); // envía el valor ingresado por el usuario al arduino, con un salto de línea al final para indicar que es el final del comando
        _sub?.cancel(); // camcela la suscripción
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dato enviado (fallback)')));
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.medical_services, size: 32),
            SizedBox(width: 10),
            Text("CTB-UPM", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: Center(
        
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

  // ---------- Limpieza ----------
  @override
  void dispose() {
    _sub?.cancel(); // cancela la suscripción al stream para evitar fugas de memoria
    _controller.dispose(); // limpia el controlador del TextField
    super.dispose(); // llama al método dispose de la clase padre para asegurarse de que se limpien correctamente
  }
}
