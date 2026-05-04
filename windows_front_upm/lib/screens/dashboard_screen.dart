import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminService api;

  const AdminDashboardScreen({super.key, required this.api});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color transferButtonColor = Color.fromARGB(255, 79, 71, 99);
  final Color createButtonColor = Color(0xFF009688);
  List<Map<String, dynamic>> devices = [];

  String? selectedSerial;
  String? selectedOwner;

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
      devices = List<Map<String, dynamic>>.from(ds);
    } catch (e) {
      _show('Error cargando devices: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _selectDevice(Map<String, dynamic> device) async {
    final serial = device['serialNumber'];
    final owner = device['ownerName'];

    setState(() {
      loading = true;
      selectedSerial = serial;
      selectedOwner = owner;
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
      _show('Dispositivo creado');
    } catch (e) {
      _show('Error creando dispositivo: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _deleteDevice(String serial) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('Eliminar dispositivo $serial?'),
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
      _show('Dispositivo eliminado');
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
      await _selectDevice({
        'serialNumber': selectedSerial,
        'ownerName': selectedOwner,
      });
      _show('Sesiones recargadas');
    } catch (e) {
      _show(e.toString());
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
        title: const Text("CTB-UPM"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadDevices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Panel lateral
                Container(
                  width: 320,
                  decoration: const BoxDecoration(color: Color(0xFF111827)),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.memory, color: Colors.white, size: 40),
                      const SizedBox(height: 10),
                      const Text(
                        "DISPOSITIVOS",
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
                            final selected = d['serialNumber'] == selectedSerial;

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
                                  d['serialNumber'],
                                  style: const TextStyle(color: Colors.white),
                                ),

                                subtitle: Row(
                                  children: [
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        (d['ownerName'] != null && d['ownerName'].toString().isNotEmpty)
                                            ? d['ownerName'].toString()[0].toUpperCase() +
                                                d['ownerName'].toString().substring(1)
                                            : '',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                onTap: () => _selectDevice(d),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _deleteDevice(d['serialNumber']),
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
                            _buildInput(serialCtrl, "Número serial"),
                            const SizedBox(height: 8),
                            _buildInput(ownerCtrl, "Nombre del usuario"),
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
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Crear Dispositivo",
                                  style: TextStyle(color: Colors.white),
                                ),
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
                              "Seleccione un dispositivo para ver detalles",
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Dispositivo: $selectedSerial",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            (selectedOwner != null &&
                                                    selectedOwner!.isNotEmpty)
                                                ? selectedOwner![0]
                                                          .toUpperCase() +
                                                      selectedOwner!.substring(
                                                        1,
                                                      )
                                                : "Sin propietario",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                if (status != null)
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Sesiones pendientes",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          "${status!['pendingSessions']}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Recargar sesiones",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: rechargeCtrl,
                                              decoration: InputDecoration(
                                                hintText: "Cantidad",
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF0F172A,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 14,
                                                  ),
                                            ),
                                            onPressed: _recharge,
                                            child: const Icon(Icons.add),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Historial",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                     SizedBox(
                                        height: 300,
                                        child: ListView.builder(
                                          itemCount: history.length,
                                          itemBuilder: (_, i) {
                                            final h = history[i];

                                            final type = (h["type"] ?? "")
                                                .toString();
                                            final amount = h["amount"] ?? 0;
                                            final timestamp =
                                                h["timestamp"] ?? "";

                                            IconData getIcon(String t) {
                                              switch (t.toUpperCase()) {
                                                case "RECHARGE":
                                                  return Icons
                                                      .add_circle_outline;

                                                case "TRANSFER":
                                                case "LOAD_TO_ARDUINO":
                                                  return Icons.usb;

                                                default:
                                                  return Icons.history;
                                              }
                                            }

                                            Color getColor(String t) {
                                              switch (t.toUpperCase()) {
                                                case "RECHARGE":
                                                  return Colors.green;

                                                case "TRANSFER":
                                                case "LOAD_TO_ARDUINO":
                                                  return Colors.blue;

                                                default:
                                                  return Colors.grey;
                                              }
                                            }

                                            final color = getColor(type);

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: color.withOpacity(0.3),
                                                ),
                                              ),
                                              child: ListTile(
                                                leading: Icon(
                                                  getIcon(type),
                                                  color: color,
                                                ),

                                                title: Text(
                                                  formatHistoryType(type),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),

                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Cantidad: $amount"),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatDate(timestamp),
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
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

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return raw;
    }
  }

  String formatHistoryType(String type) {
    switch (type.toUpperCase()) {
      case "RECHARGE":
        return "Recarga";

      case "LOAD_TO_ARDUINO":
        return "Cargado al dispositivo";

      case "TRANSFER":
        return "Transferencia";

      default:
        return type;
    }
  }
}
