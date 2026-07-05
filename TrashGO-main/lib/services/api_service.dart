import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Direccion base del backend.
// 10.0.2.2 es la forma en que el emulador de Android ve la "localhost" del PC.
const String baseUrl = "http://10.0.2.2:8000";

// Clase que se comunica con el backend (servidor).
// Todos los metodos son estaticos para poder llamarlos sin crear un objeto.
class ApiService {
  // Ayudante privado: saca el mensaje de error del campo "detail" del JSON.
  // Si no existe, devuelve un mensaje generico.
  static String _extraerError(String body) {
    try {
      final datos = jsonDecode(body);
      if (datos is Map && datos['detail'] != null) {
        return datos['detail'].toString();
      }
    } catch (_) {
      // Si el body no era JSON valido, seguimos al mensaje generico
    }
    return "Ocurrió un error";
  }

  // Registra un usuario nuevo en el backend
  static Future<Map<String, dynamic>> registro(
    String nombre,
    String email,
    String password,
  ) async {
    try {
      final respuesta = await http.post(
        Uri.parse("$baseUrl/auth/registro"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
        }),
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      } else {
        // El servidor respondio con error: mostramos su mensaje
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      // No hubo conexion con el servidor
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Inicia sesion con correo y contrasena
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final respuesta = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Trae la lista de foros del backend
  static Future<List<dynamic>> getForos() async {
    try {
      final respuesta = await http.get(Uri.parse("$baseUrl/foros"));

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as List<dynamic>;
      } else {
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Crea un foro nuevo (necesita el token del usuario logueado)
  static Future<Map<String, dynamic>> crearForo(
    String titulo,
    String descripcion,
    String token,
  ) async {
    try {
      final respuesta = await http.post(
        Uri.parse("$baseUrl/foros"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'titulo': titulo, 'descripcion': descripcion}),
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Trae los mensajes de un foro segun su id
  static Future<List<dynamic>> getMensajes(int foroId) async {
    try {
      final respuesta = await http.get(
        Uri.parse("$baseUrl/foros/$foroId/mensajes"),
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as List<dynamic>;
      } else {
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Envia un mensaje a un foro (necesita el token del usuario logueado)
  static Future<Map<String, dynamic>> enviarMensaje(
    int foroId,
    String contenido,
    String token,
  ) async {
    try {
      final respuesta = await http.post(
        Uri.parse("$baseUrl/foros/$foroId/mensajes"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'contenido': contenido}),
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Trae la lista de puntos de recoleccion creados por la comunidad
  static Future<List<dynamic>> getPuntosComunitarios() async {
    try {
      final respuesta = await http.get(
        Uri.parse("$baseUrl/puntos-comunitarios"),
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as List<dynamic>;
      } else {
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Crea un punto de recoleccion nuevo (necesita el token del usuario logueado).
  // Ahora tambien manda el tipo de residuo que acepta el punto.
  static Future<Map<String, dynamic>> crearPuntoComunitario(
    String nombre,
    String descripcion,
    double latitud,
    double longitud,
    String diasRecoleccion,
    String tipoResiduo,
    String token,
  ) async {
    try {
      final respuesta = await http.post(
        Uri.parse("$baseUrl/puntos-comunitarios"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
          'latitud': latitud,
          'longitud': longitud,
          'dias_recoleccion': diasRecoleccion,
          'tipo_residuo': tipoResiduo,
        }),
      );

      if (respuesta.statusCode == 200) {
        return jsonDecode(respuesta.body) as Map<String, dynamic>;
      } else {
        throw Exception(_extraerError(respuesta.body));
      }
    } on SocketException {
      throw Exception(
        "No se pudo conectar al servidor. ¿Está encendido el backend?",
      );
    }
  }

  // Busca las coordenadas (latitud, longitud) de una direccion escrita por el
  // usuario. Esto se llama "geocoding": convertir un texto (una direccion) en
  // un punto del mapa. Usamos Nominatim de OpenStreetMap, que es gratis y no
  // necesita clave (API key).
  //
  // Devuelve un Map {'lat': ..., 'lng': ...} con las coordenadas del primer
  // resultado, o null si no se encontro la direccion.
  static Future<Map<String, double>?> buscarCoordenadas(
    String direccion,
  ) async {
    try {
      // Agregamos ", Arica y Parinacota, Chile" para que Nominatim busque
      // solo en nuestra region. Uri.encodeComponent convierte el texto a un
      // formato valido para URL (por ejemplo, cambia los espacios por %20).
      final consulta = Uri.encodeComponent(
        "$direccion, Arica y Parinacota, Chile",
      );

      // countrycodes=cl limita la busqueda a Chile.
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?format=json&limit=1&countrycodes=cl&q=$consulta",
      );

      // MUY IMPORTANTE: Nominatim EXIGE un User-Agent en la peticion.
      // Si no se lo mandamos, bloquea la respuesta.
      final respuesta = await http.get(
        url,
        headers: {'User-Agent': 'TrashGo-App-Universidad'},
      );

      if (respuesta.statusCode == 200) {
        // La respuesta es una lista de resultados en formato JSON
        final List<dynamic> resultados = jsonDecode(respuesta.body);

        // Si la lista viene vacia, no se encontro la direccion
        if (resultados.isEmpty) return null;

        // Tomamos el primer (y unico) resultado.
        // Nominatim devuelve 'lat' y 'lon' como texto, por eso usamos parse.
        final primero = resultados[0];
        return {
          'lat': double.parse(primero['lat'].toString()),
          'lng': double.parse(primero['lon'].toString()),
        };
      }

      // Cualquier otro codigo distinto de 200: no encontrado
      return null;
    } on SocketException {
      // No hay internet: avisamos con un error claro para mostrarlo en pantalla
      throw Exception("No hay conexión a internet para buscar la dirección");
    } catch (e) {
      // Cualquier otro problema inesperado: lo tratamos como "no encontrado"
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  OSRM: rutas y ajuste a calles
  //  OSRM (Open Source Routing Machine) es un servicio gratuito que sabe
  //  como estan conectadas las calles reales. Lo usamos para dos cosas:
  //  (1) "pegar" un punto a la calle mas cercana, y
  //  (2) calcular una ruta que siga las calles entre dos puntos.
  // ─────────────────────────────────────────────────────────────

  // (1) "Pega" un punto (lat, lng) a la calle mas cercana.
  // A veces las coordenadas de un punto caen encima de una casa, un cerro o
  // una zona sin calles. Este metodo le pregunta a OSRM cual es el borde de
  // calle mas cercano y devuelve ese punto corregido, para que el marcador
  // quede sobre una calle real y no "flotando" en el vacio.
  //
  // Si algo falla (sin internet, servidor caido, etc.) devolvemos el punto
  // original tal cual, para no romper la app.
  static Future<LatLng> pegarACalle(double lat, double lng) async {
    try {
      // OSRM espera las coordenadas en el orden longitud,latitud (lng,lat).
      final url = Uri.parse(
        "https://router.project-osrm.org/nearest/v1/driving/"
        "$lng,$lat",
      );

      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        // waypoints[0].location viene como [lng, lat] de la calle mas cercana
        final location = datos['waypoints'][0]['location'];
        final double lngCalle = (location[0] as num).toDouble();
        final double latCalle = (location[1] as num).toDouble();
        return LatLng(latCalle, lngCalle);
      }

      // Respuesta rara: devolvemos el punto original
      return LatLng(lat, lng);
    } catch (e) {
      // Cualquier fallo: devolvemos el punto original sin romper nada
      return LatLng(lat, lng);
    }
  }

  // (2) Calcula una ruta que sigue las CALLES reales entre origen y destino.
  // Devuelve la lista de puntos (LatLng) que forman la linea de la ruta,
  // lista para dibujarse como Polyline en el mapa. Si falla, devuelve [].
  static Future<List<LatLng>> obtenerRuta(LatLng origen, LatLng destino) async {
    try {
      // Otra vez el orden es lng,lat. Pedimos la geometria completa en GeoJSON:
      //  overview=full  -> la linea con todos sus puntos (no simplificada)
      //  geometries=geojson -> las coordenadas vienen como [lng, lat]
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
        "${origen.longitude},${origen.latitude};"
        "${destino.longitude},${destino.latitude}"
        "?overview=full&geometries=geojson",
      );

      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        // routes[0].geometry.coordinates es una lista de pares [lng, lat]
        final List<dynamic> coords =
            datos['routes'][0]['geometry']['coordinates'];

        // Convertimos cada [lng, lat] a LatLng(lat, lng) para flutter_map
        return coords.map<LatLng>((c) {
          final double lng = (c[0] as num).toDouble();
          final double lat = (c[1] as num).toDouble();
          return LatLng(lat, lng);
        }).toList();
      }

      // Sin ruta valida: lista vacia
      return [];
    } catch (e) {
      // Cualquier fallo: lista vacia (la pantalla mostrara una linea recta)
      return [];
    }
  }
}
