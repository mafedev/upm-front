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
      appBar: AppBar(
        title: const Text("Panel de Control - Arduino", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              
              // ---------- Ver sesiones ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004FA8).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _serial.send("0"); // envía el 0 al Arduino

                        _serial.stream.first.then((data) {
                          setState(() {
                            _sessions = data;
                          });
                        });
                      },
                      child: const Text("Sesiones disponibles", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0066CC), width: 1),
                        ),
                        child: Text(_sessions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF004FA8))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Ver número de serie ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004FA8).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _serial.send("1"); // envía el 1 al Arduino

                        _serial.stream.first.then((data){
                          setState(() {
                            _serialNumber = data;
                          });
                        });
                      },
                      child: const Text("Número de serie", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0066CC), width: 1),
                        ),
                        child: Text(_serialNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF004FA8))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ---------- Recargar sesiones ----------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004FA8).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Cargar nuevas sesiones", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF004FA8))),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _sessionsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0066CC), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF004FA8), width: 2),
                        ),
                        labelText: "Número de sesiones",
                        labelStyle: const TextStyle(color: Color(0xFF0066CC)),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A86B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _loadSessions,
                          child: const Text("Enviar sesiones", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_recharge, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF004FA8))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
