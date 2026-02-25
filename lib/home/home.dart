import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/serial_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  
  final SerialService _serial = SerialService(); // Instancia del servicio

  // Variables separadas para cada respuesta, permite actualizarlas de manera independiente
  String _sessions = "Sin respuesta"; // Muestra solo las sesiones disponibles
  String _serialNumber = "Sin respuesta"; // Muestra el número de serie
  String _recharge = "No se han recargado sesiones"; // Muestra el estado de la recarga

  final TextEditingController _sessionsController = TextEditingController(); // Es el que permite leer el número de sesiones a cargar

  @override
  void initState() {
    super.initState();

    // Obtiene la lista de puertos disponibles
    final ports = _serial.getAvailablePorts();
    debugPrint("Puertos disponibles: $ports");

    // si no hay puertos disponibles muestra el mensaje y sale
    if(ports.isEmpty){
      debugPrint("No se detectaron puertos disponibles");
      return;
    }

    // si hay puertos, se toma el último
    final lastPort = ports.last;
    debugPrint("Último puerto: $lastPort");
    
    // Se abre el puerto usando el método del servicio, le pasa por parámetro el puerto
    bool opened = _serial.open(lastPort);
    debugPrint("Puerto abierto: $opened"); // Debug para saber si se abrió el puerto

    // Si se abrió sin problemas
    if (opened) {
      _serial.stream.listen( // escucha el stream
        (data) {
          debugPrint("Recibido: $data");
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

  // ---------- Cargar sesiones ----------
  void _loadSessions() async {
    final value = _sessionsController.text.trim(); // obtiene el número de sesiones

    // Si está vacío, muestra el mensaje
    if (value.isEmpty) {
      setState(() {
        _recharge = "Introduce un número válido";
      });
      return;
    }

    // Se pasa a entero
    final int? number = int.tryParse(value);

    // Si no se puede porque no es un número
    if(number == null){
      setState(() {
        _recharge = "Solo se permiten números";
      });
      return;
    }

    // Para evitar que ingresen números negativos
    if (number < 0) {
      setState(() {
        _recharge = "Introduzca valores positivos";
      });
      return;
    }

    // si no cumple ninguna de las anteriores, envía la contraseña
    _serial.send("1234");

    // espera un segundo para que entre en el bucle
    await Future.delayed(const Duration(seconds: 1));

    // y por último envía el número de sesiones a cargar
    _serial.send(value);

    // Muestra un mensaje de éxito
    setState(() {
      _recharge = "¡Recargado con éxito!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arduino Menu")),
      body: Padding(
        padding: const EdgeInsets.all(20), // espaciado interno
        child: Column(
          children: [
            // ---------- Ver sesiones ----------
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _serial.send("0"); // Al presionar el botón envía un '0' al Arduino

                    // escucha la respuesta del stream
                    _serial.stream.first.then((data) {
                      setState(() {
                        _sessions = data;
                      });
                    });
                  },
                  child: const Text("Sesiones disponibles"),
                ),
                const SizedBox(width: 20),
                Text(_sessions, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 15),

            // ---------- Ver número de serie ----------
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _serial.send("1"); // Al presionar el botón envia un '1' al Arduino

                    _serial.stream.first.then((data){
                      setState(() {
                        _serialNumber = data;
                      });
                    });
                  },
                  child: const Text("Número de serie"),
                ),
                const SizedBox(width: 20),
                Text(_serialNumber, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 25),

            // ---------- Recargar sesiones ----------
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
            Row(
              children: [
                // Cuando se presiona el botón llama a la función para cargar las sesiones
                ElevatedButton(
                  onPressed: _loadSessions,
                  child: const Text("Enviar sesiones"),
                ),
                const SizedBox(width: 20),
                Text(_recharge, style: const TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
