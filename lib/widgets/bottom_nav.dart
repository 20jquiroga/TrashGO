import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int indiceSeleccionado;

  const BottomNav({super.key, required this.indiceSeleccionado});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indiceSeleccionado,
      selectedItemColor: const Color(0xFFE53935),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      onTap: (index) {
        if (index == indiceSeleccionado) return;
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/foro',
              (route) => false,
            );
          case 1:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          case 2:
            // Pantalla de perfil pendiente para Sprint 2
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Foro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Mapa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
