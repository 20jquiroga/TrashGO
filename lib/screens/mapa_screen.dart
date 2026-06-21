import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/mock_data.dart';
import '../models/punto_acopio.dart';
import '../widgets/bottom_nav.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();

  // Coordenadas del centro de Arica
  static const LatLng _centroArica = LatLng(-18.4783, -70.3126);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _mostrarDetallesPunto(PuntoAcopio punto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetPunto(punto: punto),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Capa principal del mapa OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _centroArica,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trashgo.trashgo',
              ),
              // Polilíneas de los cuadrantes de recolección
              PolylineLayer(
                polylines: cuadrantes.map((c) {
                  // Cuadrantes 1 y 2 en azul, 3 y 4 en rojo
                  final esAzul = c.numero <= 2;
                  return Polyline(
                    points: c.puntos,
                    color: esAzul
                        ? const Color.fromARGB(178, 33, 150, 243)
                        : const Color.fromARGB(178, 229, 57, 53),
                    strokeWidth: 4.0,
                  );
                }).toList(),
              ),
              // Marcadores de puntos de acopio
              MarkerLayer(
                markers: puntosAcopio
                    .map(
                      (p) => Marker(
                        point: LatLng(p.latitud, p.longitud),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _mostrarDetallesPunto(p),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              // Marcador de ubicación simulada del usuario
              const MarkerLayer(
                markers: [
                  Marker(
                    point: _centroArica,
                    width: 24,
                    height: 24,
                    child: _UbicacionUsuario(),
                  ),
                ],
              ),
            ],
          ),
          // Barra de búsqueda flotante sobre el mapa
          const Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _BarraBusqueda(),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(indiceSeleccionado: 1),
    );
  }
}

// Indicador de posición del usuario (punto celeste con halo)
class _UbicacionUsuario extends StatelessWidget {
  const _UbicacionUsuario();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(102, 3, 169, 244),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.lightBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(102, 3, 169, 244),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: CircleAvatar(
              radius: 3,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Barra de búsqueda y filtros flotante
class _BarraBusqueda extends StatelessWidget {
  const _BarraBusqueda();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(38, 0, 0, 0),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dirección del punto de acopio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Horario ▾',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: Colors.grey),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            _ChipFiltro(texto: 'Filtro ▾'),
            SizedBox(width: 8),
            _ChipFiltro(texto: 'Ordenar ▾'),
          ],
        ),
      ],
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String texto;
  const _ChipFiltro({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(20, 0, 0, 0),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(texto, style: const TextStyle(fontSize: 13)),
    );
  }
}

// Bottom sheet con detalles del punto de acopio seleccionado
class _BottomSheetPunto extends StatefulWidget {
  final PuntoAcopio punto;
  const _BottomSheetPunto({required this.punto});

  @override
  State<_BottomSheetPunto> createState() => _BottomSheetPuntoState();
}

class _BottomSheetPuntoState extends State<_BottomSheetPunto> {
  String _chipSeleccionado = 'Cerca';

  // Obtiene el cuadrante más cercano al punto de acopio (por orden de lista)
  String get _infoCuadrante {
    final idx = puntosAcopio.indexWhere((p) => p.id == widget.punto.id);
    final c = cuadrantes[idx.clamp(0, cuadrantes.length - 1)];
    return '${c.diasRecoleccion} a las ${c.hora}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar dirección',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Código del punto de acopio: ${widget.punto.id}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(widget.punto.direccion, style: const TextStyle(fontSize: 15)),
          Text(
            'Tipo de residuo: ${widget.punto.tipoResiduo}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Recolección: $_infoCuadrante',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'Guardar como',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Cerca', 'Casa', 'Trabajo'].map((chip) {
              final seleccionado = _chipSeleccionado == chip;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _chipSeleccionado = chip),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? const Color(0xFFE53935)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seleccionado
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        color: seleccionado ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Punto guardado'),
                    backgroundColor: Color(0xFFE53935),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar punto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
