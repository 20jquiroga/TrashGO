import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

// Pantalla para iniciar sesion
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Color principal de la app (rojo)
  static const Color _rojo = Color(0xFFE53935);

  // Controladores para leer lo que el usuario escribe
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  // Bandera para saber si estamos esperando la respuesta del servidor
  bool _cargando = false;

  @override
  void dispose() {
    // Liberamos los controladores cuando la pantalla se cierra
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Muestra un mensajito abajo de la pantalla
  void _mostrarMensaje(String texto, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(texto), backgroundColor: color));
  }

  // Se ejecuta al presionar "Iniciar sesion"
  Future<void> _iniciarSesion() async {
    final correo = _correoCtrl.text.trim();
    final pass = _passCtrl.text;

    // Validamos que no haya campos vacios
    if (correo.isEmpty || pass.isEmpty) {
      _mostrarMensaje('Completa todos los campos', _rojo);
      return;
    }

    // Activamos el estado de carga
    setState(() => _cargando = true);

    try {
      // Llamamos al backend para iniciar sesion
      final res = await ApiService.login(correo, pass);

      // Guardamos el token y los datos del usuario en el telefono
      await AuthStorage.guardarToken(res['access_token']);
      await AuthStorage.guardarUsuario(
        res['usuario']['nombre'],
        res['usuario']['email'],
      );

      if (!mounted) return;
      // Vamos al mapa y no dejamos volver atras al login
      Navigator.pushReplacementNamed(context, '/mapa');
    } catch (e) {
      if (!mounted) return;
      // Mostramos el error limpio (sin la palabra "Exception:")
      _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''), _rojo);
    } finally {
      // Apagamos el estado de carga si la pantalla sigue viva
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          // El scroll evita que el teclado tape los campos
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icono de camion de basura (logo de la app)
                const Icon(Icons.local_shipping, color: _rojo, size: 80),
                const SizedBox(height: 8),
                // Titulo de la app
                const Text(
                  'TrashGo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: _rojo,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitulo
                const Text(
                  'Arica, Chile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Campo del correo
                TextField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de la contrasena
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Boton ancho rojo para iniciar sesion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Si esta cargando, deshabilitamos el boton
                    onPressed: _cargando ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rojo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Boton de texto para ir al registro
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/registro'),
                  child: const Text(
                    '¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: _rojo),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
