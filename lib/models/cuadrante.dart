import 'package:latlong2/latlong.dart';

class Cuadrante {
  final String id;
  final String nombre;
  final int numero;
  final String diasRecoleccion;
  final String hora;
  final List<LatLng> puntos;

  const Cuadrante({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.diasRecoleccion,
    required this.hora,
    required this.puntos,
  });
}
