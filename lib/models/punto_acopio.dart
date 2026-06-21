class PuntoAcopio {
  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final String tipoResiduo;

  const PuntoAcopio({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.tipoResiduo,
  });
}
