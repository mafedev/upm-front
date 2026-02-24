import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/serial_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SerialService _serial = SerialService(); // Instancia del servicio
  String _response = "Sin respuesta"; // Es el texto que se muestra al presionar el botón, por defecto es "sin respuesta"
  final TextEditingController _sessionsController = TextEditingController(); // Es el que permite leer el número de sesiones a cargar

  @override
  void initState() {
    super.initState();

    // Se abre el puerto usando el método del servicio, le pasa por parámetro el puerto
    bool opened = _serial.open("COM5");
    debugPrint("Puerto abierto: $opened"); // Debug para saber si se abrió el puerto

    // Si se abrió sin problemas
    if (opened) {
      _serial.stream.listen( // escucha el stream
        (data) {
          // Cada vez que llega algo desde el Arduino lo muestra y actualiza el texto
          debugPrint("Recibido: $data");
          setState(() {
            _response = data;
          });
        },
        onError: (error) {
          debugPrint("Error en listener: $error");
        },
        onDone: () {
          debugPrint("Stream cerrado");
        },
      );
    }
  }

  @override
  void dispose() {
    _serial.close(); // Cierra el puerto
    super.dispose();
  }

  // Cargar sesiones
  void _loadSessions() async {
    final value = _sessionsController.text.trim(); // obtiene el número de sesiones

    // Si está vacío, muestra el mensaje
    if (value.isEmpty) {
      setState(() {
        _response = "Introduce un número válido";
      });
      return;
    }

    // Se pasa a entero
    final int? number = int.tryParse(value);

    // Si no se puede porque no es un número
    if(number == null){
      setState(() {
        _response = "Solo se permiten números";
      });
      return;
    }

    // Para evitar que ingresen números negativos
    if (number < 0) {
      setState(() {
        _response = "Introduzca valores positivos";
      });
      return;
    }

    // si no cumple ninguna de las anteriores, envía la contraseña
    _serial.send("1234");

    // espera un segundo para que entre en el bucle
    await Future.delayed(const Duration(seconds: 1));

    // y por último envía el número de sesiones a cargar
    _serial.send(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arduino Menu")),
      body: Padding(
        padding: const EdgeInsets.all(20), // espaciado interno
        child: Column(
          children: [
            Text(
              _response, // Datos que le llegaron
              style: const TextStyle(fontSize: 18)
            ),
            const SizedBox(height: 30),

            // ---------- Ver sesiones ----------
            ElevatedButton(
              onPressed: () => _serial.send("0"), // Al presionar el botón envía un '0' al Arduino
              child: const Text("Sesiones disponibles"),
            ),

            const SizedBox(height: 15),

            // ---------- Ver número de serie ----------
            ElevatedButton(
              onPressed: () =>_serial.send("1"), // Al presionar el botón envia un '1' al Arduino
            child: const Text("Número de serie")),
            
            const SizedBox(height: 25),

            // ---------- Cargar sesiones ----------
            const Text("Cargar sesiones", style: TextStyle(fontSize: 16)),

            const SizedBox(height: 10),

            // Campo de texto donde se introducen el número de sesiones a cargar
            TextField(
              controller: _sessionsController, // controlador que almacena el número
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Número de sesiones",
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Solo permite introducir dígitos del 0 al 9
            ),

            const SizedBox(height: 10),

            // Cuando se presiona el botón llama a la función para cargar las sesiones
            ElevatedButton(
              onPressed: _loadSessions,
              child: const Text("Enviar sesiones"),
            ),
          ],
        ),
      ),
    );
  }
}
