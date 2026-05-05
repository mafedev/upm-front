import 'package:flutter/material.dart';

class MainNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // índice actual para resaltar el botón correspondiente
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
      ],
    );
  }
}
