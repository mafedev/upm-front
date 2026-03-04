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

    const String password = "1234";
    final String comando = "LOAD:$password:$number";
    _ble.send(comando);
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
          padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _ble.send("0");
                      },
                      child: const Text("Sesiones", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0066CC), width: 1),
                        ),
                        child: Text(_sessions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF004FA8))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _ble.send("1");
                      },
                      child: const Text("Serie", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0066CC), width: 1),
                        ),
                        child: Text(_serialNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF004FA8))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---------- Recargar sesiones ----------
              Container(
                padding: const EdgeInsets.all(18),
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
                    const Text("Cargar nuevas sesiones", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF004FA8))),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A86B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _loadSessions,
                          child: const Text("Enviar", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_recharge, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF004FA8))),
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
