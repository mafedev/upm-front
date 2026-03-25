import 'package:flutter/material.dart';
import 'serial_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SerialTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SerialTestPage extends StatefulWidget {
  const SerialTestPage({super.key});

  @override
  State<SerialTestPage> createState() => _SerialTestPageState();
}

class _SerialTestPageState extends State<SerialTestPage> {
  final SerialService serial = SerialService();

  bool isConnected = false;
  String log = "";

  @override
  void initState() {
    super.initState();

    serial.startAutoConnect();

    serial.connectionStream.listen((connected) {
      setState(() {
        isConnected = connected;
      });
    });

    serial.dataStream.listen((data) {
      setState(() {
        log = "$data\n$log";
      });
    });
  }

  @override
  void dispose() {
    serial.dispose();
    super.dispose();
  }

  void send(String cmd) {
    serial.send(cmd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Arduino USB")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔵 ESTADO
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(isConnected ? "Conectado" : "Desconectado"),
              ],
            ),

            const SizedBox(height: 20),

            // 🔘 BOTONES
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => send("GET_SESIONES"),
                  child: const Text("Leer sesiones"),
                ),
                ElevatedButton(
                  onPressed: () => send("SET_SESIONES:10"),
                  child: const Text("Set sesiones 10"),
                ),
                ElevatedButton(
                  onPressed: () => send("GET_SERIAL"),
                  child: const Text("Leer serial"),
                ),
                ElevatedButton(
                  onPressed: () => send("GET_TOTAL"),
                  child: const Text("Leer total"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 📜 LOG
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.black,
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    log,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}