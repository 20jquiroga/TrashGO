import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/foro.dart';
import '../widgets/bottom_nav.dart';

class ForoScreen extends StatelessWidget {
  const ForoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda superior
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _BarraBusquedaForo(),
            ),
            // Lista de foros
            Expanded(
              child: ListView.separated(
                itemCount: foros.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, i) {
                  final foro = foros[i];
                  return _ItemForo(foro: foro);
                },
              ),
            ),
            // Paginación visual
            const _Paginacion(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(indiceSeleccionado: 0),
    );
  }
}

class _BarraBusquedaForo extends StatelessWidget {
  const _BarraBusquedaForo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buscar foro',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
          const Icon(Icons.edit_outlined, color: Colors.grey),
        ],
      ),
    );
  }
}

class _ItemForo extends StatelessWidget {
  final Foro foro;
  const _ItemForo({required this.foro});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        foro.nombre,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        foro.ultimoMensaje,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        foro.fecha,
        style: TextStyle(color: Colors.grey[500], fontSize: 11),
      ),
      onTap: () => Navigator.pushNamed(context, '/chat', arguments: foro),
    );
  }
}

// Paginación visual — solo decorativa en Sprint 1
class _Paginacion extends StatelessWidget {
  const _Paginacion();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NumeroPagina(numero: '1', seleccionado: true),
          _NumeroPagina(numero: '2'),
          _NumeroPagina(numero: '3'),
          _NumeroPagina(numero: '4'),
          Text(
            ' ... ',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          _NumeroPagina(numero: '67'),
          _NumeroPagina(numero: '68'),
          _NumeroPagina(numero: '69'),
        ],
      ),
    );
  }
}

class _NumeroPagina extends StatelessWidget {
  final String numero;
  final bool seleccionado;
  const _NumeroPagina({required this.numero, this.seleccionado = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color:
            seleccionado ? const Color(0xFFE53935) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        numero,
        style: TextStyle(
          color: seleccionado ? Colors.white : Colors.grey[600],
          fontSize: 13,
          fontWeight:
              seleccionado ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
