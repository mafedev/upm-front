import 'package:flutter/material.dart';
import '../services/serial_service.dart';
import '../services/session_service.dart';
import 'input_screen.dart';
import '../widgets/appbar.dart';

class AdminScreen extends StatefulWidget {
  final SerialService serialService;
  final SessionService sessionService;
  final VoidCallback? onLogout;
  final bool arduinoConnected;

  const AdminScreen({
    super.key,
    required this.serialService,
    required this.sessionService,
    this.onLogout,
    this.arduinoConnected = false,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController passwordCtrl = TextEditingController();
  bool showPassword = false;

  // ---------------- LOGIN ----------------
  void checkPassword() {
    widget.sessionService.login(passwordCtrl.text);

    if (widget.sessionService.authenticated) {
      setState(() {
        passwordCtrl.clear();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Contraseña incorrecta")));
    }
  }

  // ---------------- LOGOUT ----------------
  void _logout() {
    widget.sessionService.logout();

    setState(() {}); // refresca UI

    widget.onLogout?.call(); // opcional (volver a home, etc)
  }

  // ---------------- RESET ----------------
  Future<void> confirmReset() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reiniciar total sesiones'),
        content: const Text('¿Está seguro que desea reiniciar el total de sesiones?'),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Reiniciar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.serialService.send("RESET_TOTAL:1234");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reinicio solicitado')),
        );
      }
    }
  }

  // ---------------- INPUT ----------------
  void _openInput(String label, Function(String) onSend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputScreen(label: label, onSend: onSend),
      ),
    );
  }

  // ---------------- LOGIN UI ----------------
  Widget _buildLoginCard() {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF1E88E5)),
              const SizedBox(height: 10),
              const Text(
                "Acceso Administrador",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: passwordCtrl,
                obscureText: !showPassword,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Contraseña',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: checkPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Entrar",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BOTONES ----------------
  Widget _dashboardButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- PANEL ADMIN ----------------
  Widget _buildAdminPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 2,
        ),
        children: [
          _dashboardButton(
            icon: Icons.add_task,
            label: "Cargar sesiones",
            color: const Color(0xFF43A047),
            onTap: () => _openInput(
              "Número de sesiones",
              (value) => widget.serialService.send("SET_SESIONES:$value"),
            ),
          ),
          _dashboardButton(
            icon: Icons.edit,
            label: "Cambiar número de serie",
            color: const Color(0xFF1E88E5),
            onTap: () => _openInput(
              "Nuevo número de serie",
              (value) => widget.serialService.send("SET_SERIAL:$value"),
            ),
          ),
          _dashboardButton(
            icon: Icons.restart_alt,
            label: "Reiniciar total sesiones",
            color: Colors.red,
            onTap: confirmReset,
          ),
        ],
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final authenticated = widget.sessionService.authenticated;

    return Column(
      children: [
        if (authenticated)
          SystemAppBar(
            subtitle: "Panel Administrador",
            showLogout: true,
            onLogout: _logout,
          ),

        Expanded(
          child: authenticated
              ? _buildAdminPanel()
              : _buildLoginCard(),
        ),
      ],
    );
  }
}