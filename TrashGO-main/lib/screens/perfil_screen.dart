import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '../widgets/bottom_nav.dart';

// Pantalla de perfil del usuario
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // Color principal de la app (rojo)
  static const Color _rojo = Color(0xFFE53935);

  // Aqui guardamos el nombre y el correo que leemos del telefono
  String? _nombre;
  String? _email;

  @override
  void initState() {
    super.initState();
    // Al abrir la pantalla, cargamos los datos guardados
    _cargarDatos();
  }

  // Lee el nombre y el correo desde el almacenamiento local
  Future<void> _cargarDatos() async {
    final nombre = await AuthStorage.obtenerNombreUsuario();
    final email = await AuthStorage.obtenerEmailUsuario();
    if (!mounted) return;
    setState(() {
      _nombre = nombre;
      _email = email;
    });
  }

  // Cierra la sesion y vuelve al login
  Future<void> _cerrarSesion() async {
    await AuthStorage.cerrarSesion();
    if (!mounted) return;
    // Vamos al login y borramos todo el historial de pantallas
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Perfil', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Foto de perfil (un icono dentro de un circulo rojo claro)
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFFFCDD2),
                child: Icon(Icons.person, size: 60, color: _rojo),
              ),
              const SizedBox(height: 20),

              // Nombre del usuario (si no cargo aun, muestra "—")
              Text(
                _nombre ?? '—',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Correo del usuario
              Text(
                _email ?? '—',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Boton ancho rojo para cerrar sesion
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rojo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Barra de navegacion inferior (perfil es el indice 2)
      bottomNavigationBar: const BottomNav(indiceSeleccionado: 2),
    );
  }
}
