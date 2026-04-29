import 'package:flutter/material.dart';
import 'package:android_front_upm/widgets/appbar.dart';
import '../services/serial_service.dart';

class HomeScreen extends StatefulWidget {
  final SerialService serial;
  final bool arduinoConnected;

  const HomeScreen({
    super.key,
    required this.serial,
    this.arduinoConnected = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int sesiones = 0;
  int total = 0;
  String serialNumber = "0";

  bool _loading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      if (widget.serial.isConnected) {
        final s = await widget.serial.getSessions();
        final t = await widget.serial.getTotalSessions();
        final sn = await widget.serial.getSerial();

        setState(() {
          sesiones = s;
          total = t;
          serialNumber = sn;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _loading = false);
      _controller.forward(from: 0);
    }
  }

  Widget _card(String title, String value, Color color, IconData icon, int i) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.2 * i, 1.0, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(anim),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final connected = widget.serial.isConnected;

    return Column(
      children: [
        SystemAppBar(
          subtitle: "Sistema de monitorización Arduino",
          isConnected: widget.serial.isConnected,
          actions: [
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              onPressed: _loadData,
            ),
          ],
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFF4F7FB),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _card(
                        "Sesiones restantes",
                        sesiones.toString(),
                        const Color(0xFF2563EB),
                        Icons.timer,
                        0,
                      ),
                      _card(
                        "Total sesiones",
                        total.toString(),
                        const Color(0xFF16A34A),
                        Icons.bar_chart,
                        1,
                      ),
                      _card(
                        "Número de serie",
                        serialNumber,
                        const Color(0xFF7C3AED),
                        Icons.qr_code,
                        2,
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "ESTADO DEL SISTEMA",
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.serial.isConnected
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: widget.serial.isConnected
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                widget.serial.isConnected
                                    ? "Arduino conectado correctamente"
                                    : "Arduino desconectado · modo lectura limitado",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
