import 'package:shared_preferences/shared_preferences.dart';

// Clase que guarda y lee los datos de sesion del usuario en el telefono.
// Usa shared_preferences, que es como una pequena memoria local del celular.
class AuthStorage {
  // Nombres de las "cajitas" donde guardamos cada dato
  static const String _claveToken = 'token';
  static const String _claveNombre = 'nombre';
  static const String _claveEmail = 'email';

  // Guarda el token de sesion que nos dio el backend al iniciar sesion
  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveToken, token);
  }

  // Devuelve el token guardado (o null si no hay ninguno)
  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveToken);
  }

  // Guarda el nombre y el correo del usuario
  static Future<void> guardarUsuario(String nombre, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveNombre, nombre);
    await prefs.setString(_claveEmail, email);
  }

  // Devuelve el nombre guardado del usuario
  static Future<String?> obtenerNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveNombre);
  }

  // Devuelve el correo guardado del usuario
  static Future<String?> obtenerEmailUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveEmail);
  }

  // Borra todos los datos de la sesion (cerrar sesion)
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveToken);
    await prefs.remove(_claveNombre);
    await prefs.remove(_claveEmail);
  }

  // Devuelve true si hay un token guardado y no esta vacio
  static Future<bool> hayTokenGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_claveToken);
    return token != null && token.isNotEmpty;
  }
}
