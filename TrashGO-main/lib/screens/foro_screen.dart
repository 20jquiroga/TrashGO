import 'package:flutter/material.dart';
import '../models/foro_api.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/bottom_nav.dart';

// Color principal rojo de la app.
const Color _rojo = Color(0xFFE53935);

// Pantalla que muestra la lista de foros traídos desde el backend.
class ForoScreen extends StatefulWidget {
  const ForoScreen({super.key});

  @override
  State<ForoScreen> createState() => _ForoScreenState();
}

class _ForoScreenState extends State<ForoScreen> {
  List<ForoApi> _foros = []; // foros descargados de la API
  bool _cargando = true; // indica si estamos esperando la respuesta
  String _busqueda = ''; // texto escrito en el buscador
  // Filtro por tipo: 'todos', 'foro' o 'denuncia'. Empieza mostrando todos.
  String _filtroTipo = 'todos';
  final TextEditingController _buscadorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Apenas se abre la pantalla, pedimos los foros al backend.
    _cargarForos();
  }

  @override
  void dispose() {
    _buscadorCtrl.dispose(); // liberamos el controlador al cerrar
    super.dispose();
  }

  // Pide la lista de foros al backend y actualiza la pantalla.
  Future<void> _cargarForos() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.getForos();
      // Convertimos cada mapa JSON en un objeto ForoApi.
      _foros = data.map((j) => ForoApi.fromJson(j)).toList();
    } catch (e) {
      // Si algo falla mostramos el error en una barrita roja.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _rojo));
      }
    } finally {
      // Pase lo que pase, dejamos de mostrar el "cargando".
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Devuelve los foros filtrados según el buscador Y el filtro de tipo.
  List<ForoApi> get _forosFiltrados {
    final texto = _busqueda.trim().toLowerCase();
    return _foros.where((f) {
      // (1) Filtro por tipo: 'todos' deja pasar todo; si no, debe coincidir.
      final pasaTipo = _filtroTipo == 'todos' || f.tipo == _filtroTipo;
      // (2) Filtro por texto del buscador (por título).
      final pasaTexto = texto.isEmpty || f.titulo.toLowerCase().contains(texto);
      return pasaTipo && pasaTexto;
    }).toList();
  }

  // Muestra el diálogo para crear un nuevo foro.
  void _mostrarDialogoNuevoForo() {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    // Tipo elegido dentro del diálogo. Por defecto es un foro normal.
    String tipoElegido = 'foro';

    showDialog(
      context: context,
      // StatefulBuilder permite cambiar el chip elegido dentro del diálogo.
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Nuevo tema',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de tipo: "Foro" (normal) o "Denuncia" (reporte).
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Foro'),
                    selected: tipoElegido == 'foro',
                    selectedColor: Colors.blue.shade100,
                    onSelected: (_) =>
                        setDialogState(() => tipoElegido = 'foro'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('⚠️ Denuncia'),
                    selected: tipoElegido == 'denuncia',
                    selectedColor: Colors.red.shade100,
                    onSelected: (_) =>
                        setDialogState(() => tipoElegido = 'denuncia'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título del tema',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              // Al tocar "Crear" llamamos a la función que crea en el backend.
              onPressed: () =>
                  _crearForo(ctx, tituloCtrl.text, descCtrl.text, tipoElegido),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rojo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  // Crea un foro en el backend usando el token del usuario logueado.
  Future<void> _crearForo(
    BuildContext dialogCtx,
    String titulo,
    String descripcion,
    String tipo,
  ) async {
    final t = titulo.trim();
    final d = descripcion.trim();
    // El título es obligatorio.
    if (t.isEmpty) return;

    // Guardamos las referencias ANTES del await para no usar el context
    // después de una operación asíncrona (buena práctica en Flutter).
    final navegador = Navigator.of(dialogCtx);
    final mensajes = ScaffoldMessenger.of(context);

    // Buscamos el token guardado (indica que hay sesión iniciada).
    final token = await AuthStorage.obtenerToken();

    if (token == null || token.isEmpty) {
      // Sin sesión no se puede crear: cerramos el diálogo y avisamos.
      if (!mounted) return;
      navegador.pop();
      mensajes.showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para crear un foro'),
        ),
      );
      return;
    }

    try {
      await ApiService.crearForo(t, d, tipo, token);
      if (!mounted) return;
      navegador.pop(); // cerramos el diálogo
      await _cargarForos(); // recargamos la lista para ver el nuevo foro
    } catch (e) {
      // Si falla la creación mostramos el error en rojo.
      if (!mounted) return;
      mensajes.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: _rojo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _forosFiltrados;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade200,
        title: const Text(
          'Foros',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda con el lápiz rojo para crear foros.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _buscadorCtrl,
                  // Cada vez que se escribe, actualizamos el filtro.
                  onChanged: (valor) => setState(() => _busqueda = valor),
                  decoration: InputDecoration(
                    hintText: 'Buscar foro',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    // Lápiz rojo a la derecha: abre el diálogo de nuevo foro.
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: _rojo),
                      onPressed: _mostrarDialogoNuevoForo,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            // Filtro por tipo: Todos / Foros / Denuncias.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _ChipFiltroTipo(
                    texto: 'Todos',
                    seleccionado: _filtroTipo == 'todos',
                    onTap: () => setState(() => _filtroTipo = 'todos'),
                  ),
                  const SizedBox(width: 8),
                  _ChipFiltroTipo(
                    texto: 'Foros',
                    seleccionado: _filtroTipo == 'foro',
                    onTap: () => setState(() => _filtroTipo = 'foro'),
                  ),
                  const SizedBox(width: 8),
                  _ChipFiltroTipo(
                    texto: 'Denuncias',
                    seleccionado: _filtroTipo == 'denuncia',
                    onTap: () => setState(() => _filtroTipo = 'denuncia'),
                  ),
                ],
              ),
            ),
            // Zona de la lista (o cargando, o vacío).
            Expanded(child: _construirLista(lista)),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(indiceSeleccionado: 0),
    );
  }

  // Decide qué mostrar en el cuerpo: spinner, mensaje vacío o la lista.
  Widget _construirLista(List<ForoApi> lista) {
    // Si aún estamos esperando la respuesta, mostramos el círculo de carga.
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _rojo));
    }

    // Si no hay foros que mostrar, un mensaje centrado.
    // Usamos ListView con physics "siempre desplazable" para que igual
    // funcione el gesto de deslizar hacia abajo y recargar.
    if (lista.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarForos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(
                'Aún no hay foros 📭\nCrea el primero tocando el lápiz',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    // Lista normal de foros, envuelta para poder recargar deslizando.
    return RefreshIndicator(
      onRefresh: _cargarForos,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: lista.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (_, i) => _ItemForo(foro: lista[i]),
      ),
    );
  }
}

// Muestra un foro de la lista como un ListTile.
class _ItemForo extends StatelessWidget {
  final ForoApi foro;
  const _ItemForo({required this.foro});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Row(
        children: [
          // Etiqueta de color según el tipo: roja para denuncia, azul para foro.
          _ChipTipo(esDenuncia: foro.esDenuncia),
          const SizedBox(width: 8),
          // El título ocupa el resto de la fila.
          Expanded(
            child: Text(
              foro.titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          // Descripción en gris, máximo 2 líneas.
          Text(
            foro.descripcion,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Fecha de creación en gris pequeño.
          Text(
            foro.fechaCorta,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
      // Al tocar el foro (o la denuncia) vamos al chat pasándole id y título.
      // Las denuncias funcionan igual que un foro: se puede comentar dentro.
      onTap: () => Navigator.pushNamed(
        context,
        '/chat',
        arguments: {'foroId': foro.id, 'titulo': foro.titulo},
      ),
    );
  }
}

// Etiqueta pequeña que indica si un tema es "Denuncia" (roja) o "Foro" (azul).
class _ChipTipo extends StatelessWidget {
  final bool esDenuncia;
  const _ChipTipo({required this.esDenuncia});

  @override
  Widget build(BuildContext context) {
    // Elegimos color y texto según sea denuncia o foro normal.
    final color = esDenuncia ? _rojo : Colors.blue;
    final texto = esDenuncia ? '⚠️ Denuncia' : 'Foro';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Chip del filtro superior (Todos / Foros / Denuncias). Se pinta rojo cuando
// está seleccionado y gris cuando no.
class _ChipFiltroTipo extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltroTipo({
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? _rojo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? _rojo : Colors.grey.shade300,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            color: seleccionado ? Colors.white : Colors.black87,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
