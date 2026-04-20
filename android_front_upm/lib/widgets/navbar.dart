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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), // botón para la pantalla principal, con un icono de casa
        BottomNavigationBarItem(icon: Icon(Icons.vertical_align_bottom_sharp), label: "Recargar Sesiones"), // segundo botón para recargar sesiones al arduino
      ],
    );
  }
}
