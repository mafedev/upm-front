import 'package:android_front_upm/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:android_front_upm/widgets/appbar.dart';
import '../services/serial_service.dart';
import '../theme/app_colors.dart';

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
      duration: const Duration(milliseconds: 800),
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

  Widget _card({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required int index,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.15 * index, 1.0, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 10,
          ),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(), style: AppTextStyles.labelSmall),
                    const SizedBox(height: 6),
                    Text(value, style: AppTextStyles.headingLarge),
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
            color: AppColors.background,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.only(top: 6),
                    children: [
                      _card(
                        title: "Sesiones restantes",
                        value: sesiones.toString(),
                        color: AppColors.primary,
                        icon: Icons.timer,
                        index: 0,
                      ),
                      _card(
                        title: "Total sesiones",
                        value: total.toString(),
                        color: AppColors.success,
                        icon: Icons.bar_chart,
                        index: 1,
                      ),
                      _card(
                        title: "Número de serie",
                        value: serialNumber,
                        color: AppColors.purple,
                        icon: Icons.qr_code,
                        index: 2,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
