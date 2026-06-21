import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/foro.dart';
import '../widgets/bottom_nav.dart';

class ChatForoScreen extends StatelessWidget {
  const ChatForoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foro = ModalRoute.of(context)?.settings.arguments as Foro?;
    final nombreForo = foro?.nombre ?? 'Chat';

    // Solo el foro de Lynch tiene mensajes mock; el resto abre vacío
    final List<MensajeForo> mensajes =
        foro?.id == '1' ? mensajesLynch : const [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          nombreForo,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensajes del chat
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mensajes.length,
              itemBuilder: (context, i) {
                final msg = mensajes[i];
                if (msg.esArchivo) return _BurbujaArchivo(mensaje: msg);
                if (msg.esMio) return _BurbujaPropia(mensaje: msg);
                return _BurbujaAjena(mensaje: msg);
              },
            ),
          ),
          // Barra de escritura inferior
          const _BarraEscritura(),
        ],
      ),
      bottomNavigationBar: const BottomNav(indiceSeleccionado: 0),
    );
  }
}

// Burbuja de mensaje de otro usuario
class _BurbujaAjena extends StatelessWidget {
  final MensajeForo mensaje;
  const _BurbujaAjena({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final inicial =
        mensaje.autor.isNotEmpty ? mensaje.autor[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              inicial,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje.autor,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(mensaje.contenido, style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 2),
                Text(
                  mensaje.hora,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Burbuja de mensaje propio
class _BurbujaPropia extends StatelessWidget {
  final MensajeForo mensaje;
  const _BurbujaPropia({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF424242),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    mensaje.contenido,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mensaje.hora,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Burbuja especial para mensajes de tipo archivo compartido
class _BurbujaArchivo extends StatelessWidget {
  final MensajeForo mensaje;
  const _BurbujaArchivo({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.grey[300]),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file_outlined, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Archivo compartido\n(Foto, imagen, video, archivo,...)',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Barra de herramientas inferior para escribir mensajes
class _BarraEscritura extends StatelessWidget {
  const _BarraEscritura();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, color: Colors.grey, size: 22),
          const SizedBox(width: 8),
          const Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 22),
          const SizedBox(width: 8),
          const Icon(Icons.menu, color: Colors.grey, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.search, color: Colors.grey, size: 22),
        ],
      ),
    );
  }
}
