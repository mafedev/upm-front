import 'package:flutter/material.dart';

class SystemAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final bool showLogout;
  final VoidCallback? onLogout;
  final List<Widget>? actions;

  const SystemAppBar({
    super.key,
    required this.subtitle,
    this.showLogout = false,
    this.onLogout,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70); // altura total del AppBar

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top; // altura barra de estado

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 12,   // espacio arriba dinámico
        bottom: 18,               // espacio pequeño abajo
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.medical_services, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // centrado vertical
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CTB-UPM",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
          if (showLogout)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: onLogout,
            ),
        ],
      ),
    );
  }
}
