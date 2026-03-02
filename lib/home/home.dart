import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ble_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  
  final BleService _ble = BleService(); // Instancia del servicio

  // Variables separadas para cada respuesta, permite actualizarlas de manera independiente
  String _sessions = "Sin respuesta"; // Muestra solo las sesiones disponibles
  String _serialNumber = "Sin respuesta"; // Muestra el número de serie
  String _recharge = "No se han recargado sesiones"; // Muestra el estado de la recarga

  final TextEditingController _sessionsController = TextEditingController(); // Es el que permite leer el número de sesiones a cargar

  @override
  void initState() {
    super.initState();

    _ble.connect();

    _ble.stream.listen((data) {
      setState(() {
        if (data.startsWith("Sesiones:")) {
          _sessions = data;
        } else if (data.startsWith("Serie:")) {
          _serialNumber = data;
        } else {
          _recharge = data;
        }
      });
    });
  }

  @override
  void dispose() {
    _ble.disconnect();
    super.dispose();
  }

  // ---------- Cargar sesiones ----------
  void _loadSessions() {
  final value = _sessionsController.text.trim();

  if (value.isEmpty) {
    setState(() {
      _recharge = "Introduce un número válido";
    });
    return;
  }

  final int? number = int.tryParse(value);

  if (number == null || number < 0) {
    setState(() {
      _recharge = "Número inválido";
    });
    return;
  }

  _ble.send("LOAD:$number");
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
                    _ble.send("0"); // Al presionar el botón envía un '0' al Arduino

                    // escucha la respuesta del stream
                    _ble.stream.first.then((data) {
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
                    _ble.send("1"); // Al presionar el botón envia un '1' al Arduino

                    _ble.stream.first.then((data){
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
