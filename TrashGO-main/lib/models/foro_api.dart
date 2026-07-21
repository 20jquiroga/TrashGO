// Modelos que representan los datos que llegan desde el backend (API).
// Son clases simples: solo guardan datos y saben construirse desde un JSON.

// Representa un foro (un tema de conversación) que viene de la API.
class ForoApi {
  final int id; // identificador único del foro
  final String titulo; // nombre del foro
  final String descripcion; // texto que describe de qué trata
  final String tipo; // "foro" (normal) o "denuncia" (reporte de basura)
  final String autorNombre; // nombre de quien lo creó
  final DateTime createdAt; // fecha en que se creó

  // Constructor: pide todos los datos obligatorios.
  const ForoApi({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.autorNombre,
    required this.createdAt,
  });

  // Getter cómodo: true si este tema es una denuncia.
  bool get esDenuncia => tipo == 'denuncia';

  // Fábrica: construye un ForoApi a partir del mapa JSON del backend.
  factory ForoApi.fromJson(Map<String, dynamic> j) {
    return ForoApi(
      id: j['id'],
      titulo: j['titulo'] ?? '',
      descripcion: j['descripcion'] ?? '',
      // Si el backend no manda tipo (temas viejos), asumimos "foro".
      tipo: j['tipo'] ?? 'foro',
      autorNombre: j['autor_nombre'] ?? '',
      // Convertimos el texto ISO a fecha y la pasamos a hora local del celular.
      createdAt: DateTime.parse(j['created_at']).toLocal(),
    );
  }

  // Getter que arma la fecha en formato "dd/MM/yyyy HH:mm" a mano (sin intl).
  String get fechaCorta {
    final d = createdAt;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

// Representa un mensaje dentro del chat de un foro.
class MensajeApi {
  final int id; // identificador único del mensaje
  final String contenido; // texto del mensaje
  final String autorNombre; // nombre de quien lo escribió
  final DateTime createdAt; // fecha/hora en que se envió

  // Constructor con todos los datos obligatorios.
  const MensajeApi({
    required this.id,
    required this.contenido,
    required this.autorNombre,
    required this.createdAt,
  });

  // Fábrica: construye un MensajeApi desde el mapa JSON del backend.
  factory MensajeApi.fromJson(Map<String, dynamic> j) {
    return MensajeApi(
      id: j['id'],
      contenido: j['contenido'] ?? '',
      autorNombre: j['autor_nombre'] ?? '',
      createdAt: DateTime.parse(j['created_at']).toLocal(),
    );
  }

  // Getter que devuelve solo la hora en formato "HH:mm".
  String get hora {
    final d = createdAt;
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
