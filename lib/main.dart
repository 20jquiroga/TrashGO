import 'package:flutter/material.dart';
import 'screens/mapa_screen.dart';
import 'screens/foro_screen.dart';
import 'screens/chat_foro_screen.dart';

void main() {
  runApp(const TrashGoApp());
}

class TrashGoApp extends StatelessWidget {
  const TrashGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
        ),
        primaryColor: const Color(0xFFE53935),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MapaScreen(),
        '/foro': (context) => const ForoScreen(),
        '/chat': (context) => const ChatForoScreen(),
      },
    );
  }
}
