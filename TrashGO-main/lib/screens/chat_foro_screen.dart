import 'package:flutter/material.dart';
import '../models/foro_api.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

// Color principal rojo de la app.
const Color _rojo = Color(0xFFE53935);

// Pantalla del chat de un foro: muestra los mensajes y permite escribir.
class ChatForoScreen extends StatefulWidget {
  const ChatForoScreen({super.key});

  @override
  State<ChatForoScreen> createState() => _ChatForoScreenState();
}

class _ChatForoScreenState extends State<ChatForoScreen> {
  int _foroId = 0; // id del foro que estamos viendo
  String _titulo = 'Chat'; // título del foro (va en la AppBar)
  String?
  _miNombre; // nombre del usuario actual (para saber qué mensajes son míos)
  List<MensajeApi> _mensajes = []; // mensajes descargados
  bool _cargando = true; // indica si estamos esperando los mensajes
  bool _iniciado = false; // evita cargar los datos más de una vez
  final TextEditingController _mensajeCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo la primera vez: leemos los argumentos de la ruta y cargamos todo.
    // Lo hacemos aquí (y no en initState) porque necesitamos el context
    // de ModalRoute, que no está disponible en initState.
    if (!_iniciado) {
      _iniciado = true;
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _foroId = args['foroId'] as int;
      _titulo = args['titulo'] as String;
      _prepararChat();
    }
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose(); // liberamos el controlador al cerrar
    super.dispose();
  }

  // Obtiene el nombre del usuario actual y carga los mensajes.
  Future<void> _prepararChat() async {
    _miNombre = await AuthStorage.obtenerNombreUsuario();
    await _cargarMensajes();
  }

  // Pide al backend los mensajes de este foro.
  Future<void> _cargarMensajes() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.getMensajes(_foroId);
      // Convertimos cada mapa JSON en un objeto MensajeApi.
      _mensajes = data.map((j) => MensajeApi.fromJson(j)).toList();
    } catch (e) {
      // Si falla mostramos el error en rojo.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _rojo));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Envía un mensaje nuevo al foro.
  Future<void> _enviarMensaje() async {
    final texto = _mensajeCtrl.text.trim();
    // Si no hay texto, no hacemos nada.
    if (texto.isEmpty) return;

    // Necesitamos el token para saber que hay sesión iniciada.
    final token = await AuthStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comentar')),
      );
      return;
    }

    try {
      await ApiService.enviarMensaje(_foroId, texto, token);
      if (!mounted) return;
      _mensajeCtrl.clear(); // limpiamos la caja de texto
      await _cargarMensajes(); // recargamos para ver el mensaje enviado
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _rojo));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade200,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _titulo,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Zona de mensajes (o cargando, o mensaje vacío).
          Expanded(child: _construirMensajes()),
          // Barra inferior para escribir y enviar.
          _construirBarraEscritura(),
        ],
      ),
    );
  }

  // Decide qué mostrar en la zona de mensajes.
  Widget _construirMensajes() {
    // Mientras cargamos, mostramos el círculo de carga.
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _rojo));
    }

    // Si no hay mensajes, invitamos a comentar.
    if (_mensajes.isEmpty) {
      return Center(
        child: Text(
          'Sé el primero en comentar',
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      );
    }

    // Lista de mensajes. Para cada uno decidimos si es mío o de otra persona.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mensajes.length,
      itemBuilder: (context, i) {
        final msg = _mensajes[i];
        // Es mío si conozco mi nombre y coincide con el autor.
        final esMio = _miNombre != null && msg.autorNombre == _miNombre;
        if (esMio) return _BurbujaPropia(mensaje: msg);
        return _BurbujaAjena(mensaje: msg);
      },
    );
  }

  // Barra inferior con la caja de texto y el botón de enviar.
  Widget _construirBarraEscritura() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Caja de texto donde el usuario escribe el mensaje.
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _mensajeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botón redondo rojo para enviar.
            GestureDetector(
              onTap: _enviarMensaje,
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: _rojo,
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Burbuja de un mensaje escrito por otra persona (a la izquierda).
class _BurbujaAjena extends StatelessWidget {
  final MensajeApi mensaje;
  const _BurbujaAjena({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    // Inicial del autor para el círculo del avatar.
    final inicial = mensaje.autorNombre.isNotEmpty
        ? mensaje.autorNombre[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar gris con la inicial del autor.
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              inicial,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del autor arriba de la burbuja.
                Text(
                  mensaje.autorNombre,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                // Burbuja gris con el texto.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    mensaje.contenido,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 2),
                // Hora debajo, en gris pequeño.
                Text(
                  mensaje.hora,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Burbuja de un mensaje propio (a la derecha).
class _BurbujaPropia extends StatelessWidget {
  final MensajeApi mensaje;
  const _BurbujaPropia({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Burbuja oscura con el texto en blanco.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF424242),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    mensaje.contenido,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 2),
                // Hora debajo, en gris pequeño.
                Text(
                  mensaje.hora,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
