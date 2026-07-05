import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Pantalla para crear una cuenta nueva
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Color principal de la app (rojo)
  static const Color _rojo = Color(0xFFE53935);

  // Controladores para leer lo que el usuario escribe
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmarCtrl = TextEditingController();

  // Bandera de estado de carga
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  // Muestra un mensajito abajo de la pantalla
  void _mostrarMensaje(String texto, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(texto), backgroundColor: color));
  }

  // Se ejecuta al presionar "Crear cuenta"
  Future<void> _crearCuenta() async {
    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmar = _confirmarCtrl.text;

    // Validacion 1: que no falte ningun campo
    if (nombre.isEmpty || correo.isEmpty || pass.isEmpty || confirmar.isEmpty) {
      _mostrarMensaje('Completa todos los campos', _rojo);
      return;
    }
    // Validacion 2: contrasena minima de 6 caracteres
    if (pass.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres', _rojo);
      return;
    }
    // Validacion 3: las dos contrasenas deben ser iguales
    if (pass != confirmar) {
      _mostrarMensaje('Las contraseñas no coinciden', _rojo);
      return;
    }

    setState(() => _cargando = true);

    try {
      // Llamamos al backend para registrar al usuario
      // (no guardamos token aqui: el token solo se guarda al hacer login)
      await ApiService.registro(nombre, correo, pass);

      if (!mounted) return;
      // Avisamos que la cuenta se creo y pedimos iniciar sesion
      _mostrarMensaje(
        '✅ ¡Cuenta creada exitosamente! Ahora inicia sesión',
        Colors.green,
      );
      // Volvemos a la pantalla de login (se abrio desde el login)
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''), _rojo);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // La flecha de volver atras es automatica
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Crear cuenta',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo del nombre
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            // Campo para confirmar la contrasena
            TextField(
              controller: _confirmarCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Boton ancho rojo para crear la cuenta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _crearCuenta,
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
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
