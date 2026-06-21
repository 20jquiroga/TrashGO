class Foro {
  final String id;
  final String nombre;
  final String ultimoMensaje;
  final String fecha;

  const Foro({
    required this.id,
    required this.nombre,
    required this.ultimoMensaje,
    required this.fecha,
  });
}

class MensajeForo {
  final String id;
  final String contenido;
  final String autor;
  final bool esMio;
  final String hora;
  final bool esArchivo;

  const MensajeForo({
    required this.id,
    required this.contenido,
    this.autor = '',
    required this.esMio,
    required this.hora,
    this.esArchivo = false,
  });
}
