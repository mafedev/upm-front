import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/serial_service.dart';
import 'input_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminService api;
  final SerialService serialService;

  const AdminDashboardScreen({
    Key? key,
    required this.api,
    required this.serialService,
  }) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
    final Color transferButtonColor = Color.fromARGB(255, 79, 71, 99);
    final Color createButtonColor = Color(0xFF009688);
  List<String> devices = [];
  String? selectedSerial;
  Map<String, dynamic>? status;
  List<Map<String, dynamic>> history = [];

  final TextEditingController serialCtrl = TextEditingController();
  final TextEditingController ownerCtrl = TextEditingController();
  final TextEditingController rechargeCtrl = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    serialCtrl.dispose();
    ownerCtrl.dispose();
    rechargeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => loading = true);
    try {
      final ds = await widget.api.getDevices();
      devices = List<String>.from(ds);
    } catch (e) {
      _show('Error cargando devices: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _selectDevice(String serial) async {
    setState(() {
      loading = true;
      selectedSerial = serial;
      status = null;
      history = [];
    });

    try {
      final st = await widget.api.getStatus(serial);
      final h = await widget.api.getHistory(serial);
      setState(() {
        status = Map<String, dynamic>.from(st ?? {});
        history = List<Map<String, dynamic>>.from(h ?? []);
      });
    } catch (e) {
      _show('Error seleccionando device: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _createDevice() async {
    final s = serialCtrl.text.trim();
    final o = ownerCtrl.text.trim();
    if (s.isEmpty || o.isEmpty) {
      _show('Serial y owner son obligatorios');
      return;
    }

    setState(() => loading = true);
    try {
      await widget.api.createDevice(s, o);
      serialCtrl.clear();
      ownerCtrl.clear();
      await _loadDevices();
      _show('Device creado');
    } catch (e) {
      _show('Error creando device: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _deleteDevice(String serial) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('Eliminar device $serial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => loading = true);
    try {
      await widget.api.deleteDevice(serial);
      selectedSerial = null;
      status = null;
      history = [];
      await _loadDevices();
      _show('Device deleted');
    } catch (e) {
      _show(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _recharge() async {
    if (selectedSerial == null) return;
    final amountText = rechargeCtrl.text.trim();
    if (amountText.isEmpty) return;
    final amount = int.tryParse(amountText);
    if (amount == null) {
      _show('Cantidad inválida');
      return;
    }

    setState(() => loading = true);
    try {
      await widget.api.rechargeSessions(selectedSerial!, amount);
      rechargeCtrl.clear();
      await _selectDevice(selectedSerial!);
      _show('Sessions recharged');
    } catch (e) {
      _show(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _transfer() async {
    if (selectedSerial == null) return;
    setState(() => loading = true);

    try {
      final backendPending = await widget.api.getPendingSessions(
        selectedSerial!,
      );
      if (backendPending <= 0) {
        _show('No pending sessions to transfer');
        await _selectDevice(selectedSerial!);
        return;
      }

      widget.serialService.send('3');
      String? serialLine;
      try {
        serialLine = await widget.serialService.stream.first.timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        serialLine = null;
      }

      if (serialLine == null || !serialLine.contains(selectedSerial!)) {
        _show(
          'Arduino conectado no coincide o no responde: ${serialLine ?? 'sin respuesta'}',
        );
        await _selectDevice(selectedSerial!);
        return;
      }

      widget.serialService.send('2');
      String? arduinoValue;
      try {
        arduinoValue = await widget.serialService.stream.first.timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        arduinoValue = null;
      }

      final currentArduino =
          int.tryParse(arduinoValue?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
          0;
      final total = backendPending + currentArduino;

      widget.serialService.send('1');
      String? promptLine;
      try {
        promptLine = await widget.serialService.stream
            .firstWhere((l) => l.toLowerCase().contains('introduce'))
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        promptLine = null;
      }

      if (promptLine == null) {
        _show('No se recibió prompt de Arduino para introducir número');
        return;
      }

      widget.serialService.send(total.toString());

      String? confirmLine;
      try {
        confirmLine = await widget.serialService.stream
            .firstWhere((l) => l.toLowerCase().contains('sesiones cargadas'))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        confirmLine = null;
      }

      if (confirmLine == null) {
        _show(
          'No se recibió confirmación del Arduino (cuidado: pendientes no limpiados)',
        );
        return;
      }

      await widget.api.transferAllToArduino(selectedSerial!);
      await _selectDevice(selectedSerial!);
      _show('Transferido: $total');
    } catch (e) {
      _show('ERROR transfer: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Arduino Control Center"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadDevices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Container(
                  width: 320,
                  decoration: const BoxDecoration(color: Color(0xFF111827)),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.memory, color: Colors.white, size: 40),
                      const SizedBox(height: 10),
                      const Text(
                        "DEVICES",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (_, i) {
                            final d = devices[i];
                            final selected = d == selectedSerial;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1F2937)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.usb,
                                  color: Colors.white70,
                                ),
                                title: Text(
                                  d,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () => _selectDevice(d),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _deleteDevice(d),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildInput(serialCtrl, "Serial"),
                            const SizedBox(height: 8),
                            _buildInput(ownerCtrl, "Owner"),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: createButtonColor,
                                  padding: const EdgeInsets.all(14),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _createDevice,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text("Create Device", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    color: const Color(0xFFF1F3F7),
                    child: selectedSerial == null
                        ? const Center(
                            child: Text(
                              "Select a device",
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Device: $selectedSerial",
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 15),

                                if (status != null)
                                  _infoCard(
                                    "Pending sessions",
                                    "${status!['pendingSessions']}",
                                  ),

                                const SizedBox(height: 20),

                                const Text(
                                  "Recharge sessions",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: rechargeCtrl,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Enter amount",
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: _recharge,
                                      child: const Text("Add"),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: transferButtonColor,
                                    padding: const EdgeInsets.all(14),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _transfer,
                                  icon: const Icon(Icons.usb, color: Colors.white),
                                  label: const Text("Transfer to Arduino", style: TextStyle(color: Colors.white)),
                                ),

                                const SizedBox(height: 20),

                                const Text(
                                  "History",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Expanded(
                                  child: ListView.builder(
                                    itemCount: history.length,
                                    itemBuilder: (_, i) {
                                      final h = history[i];
                                      return Card(
                                        child: ListTile(
                                          leading: const Icon(Icons.history),
                                          title: Text(h["type"].toString()),
                                          subtitle: Text(
                                            "Amount: ${h["amount"]}",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInput(TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white10,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
