import 'dart:math'; // funciones matematicas para la distancia (Haversine)

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/cuadrantes_data.dart';
import '../data/mock_data.dart';
import '../models/punto_acopio.dart';
import '../models/punto_comunitario.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/bottom_nav.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();

  // Coordenadas del centro de Arica
  static const LatLng _centroArica = LatLng(-18.4783, -70.3126);

  // Controlador y texto de la barra de busqueda
  final TextEditingController _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  // Orden de la lista: 'nombre_az' o 'nombre_za'
  String _orden = 'nombre_az';

  // TODOS los puntos de recoleccion vienen del backend: los 31 oficiales base
  // + los que agregan los usuarios. Se muestran todos con el mismo icono verde.
  List<PuntoComunitario> _puntosComunitarios = [];

  // Cuando es true, el usuario esta eligiendo en el mapa donde va su punto
  bool _modoAgregar = false;

  // HU-06: controla si se ve el aviso de recoleccion de hoy.
  // Empieza en true y se pone en false cuando el usuario toca la X.
  bool _mostrarAvisoRecoleccion = true;

  // --- Filtro por tipo de basura ---

  // Tipos de residuo que se pueden filtrar (los que muestra el panel de filtro).
  static const List<String> _tiposResiduo = [
    'Orgánico',
    'Plástico',
    'Vidrio',
    'Papel/Cartón',
    'Metales',
    'Aluminio',
  ];

  // Tipos elegidos por el usuario. Si esta vacio, se muestran TODOS los puntos.
  Set<String> _tiposSeleccionados = {};

  // --- Posiciones "pegadas a la calle" (OSRM Nearest) ---

  // Guardamos en memoria (durante la sesion) la posicion corregida de cada
  // punto, usando su id como llave. Asi no volvemos a llamar a OSRM cada vez.
  // Si un punto no esta aqui todavia, usamos su posicion original.
  final Map<int, LatLng> _posCorregidas = {};

  // --- Busqueda de direccion (ruta al punto de recoleccion mas cercano) ---

  // Ubicacion del usuario segun la direccion que busco (marcador azul).
  // Si es null, todavia no ha buscado ninguna direccion.
  LatLng? _ubicacionUsuario;

  // Resultado de la busqueda: el punto de recoleccion mas cercano, la
  // distancia hasta el, y la ruta (lista de puntos) que sigue las calles.
  // Es null mientras el usuario no ha buscado ninguna direccion.
  _ResultadoRuta? _resultado;

  // Bandera para mostrar el circulito de carga mientras buscamos la direccion.
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    // Al abrir la pantalla, traemos del backend todos los puntos de recoleccion
    // (los 31 oficiales + los que hayan agregado los usuarios).
    _cargarPuntosComunitarios();
  }

  // Devuelve la posicion de un punto: la corregida por OSRM si ya la tenemos
  // en memoria, o su posicion original mientras tanto.
  LatLng _posDe(PuntoComunitario p) =>
      _posCorregidas[p.id] ?? LatLng(p.latitud, p.longitud);

  // Corrige las posiciones de los puntos "pegandolas" a la calle mas cercana.
  // Solo procesa los que aun NO tenemos en cache, para no repetir llamadas.
  // Usa Future.wait para pedirlos todos a OSRM EN PARALELO (mas rapido).
  // Si un punto falla, pegarACalle devuelve su posicion original (no desaparece).
  Future<void> _corregirPosiciones(List<PuntoComunitario> puntos) async {
    final pendientes =
        puntos.where((p) => !_posCorregidas.containsKey(p.id)).toList();
    if (pendientes.isEmpty) return;

    // Lanzamos todas las peticiones a la vez y esperamos a que terminen todas.
    final corregidas = await Future.wait(
      pendientes.map((p) => ApiService.pegarACalle(p.latitud, p.longitud)),
    );
    if (!mounted) return;

    setState(() {
      for (var i = 0; i < pendientes.length; i++) {
        _posCorregidas[pendientes[i].id] = corregidas[i];
      }
    });
  }

  // Devuelve los puntos de recoleccion que se ven en el mapa segun el filtro.
  // Si no hay filtro activo, devuelve TODOS. Si hay tipos elegidos, deja solo
  // los puntos cuyo tipoResiduo incluya alguno de esos tipos.
  List<PuntoComunitario> get _recoleccionVisibles {
    if (_tiposSeleccionados.isEmpty) return _puntosComunitarios;
    return _puntosComunitarios.where((p) {
      final tipo = p.tipoResiduo.toLowerCase();
      return _tiposSeleccionados.any((t) => tipo.contains(t.toLowerCase()));
    }).toList();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  // Trae los puntos comunitarios desde el backend.
  // Si el backend esta apagado NO rompemos la pantalla: dejamos la lista vacia.
  Future<void> _cargarPuntosComunitarios() async {
    try {
      final datos = await ApiService.getPuntosComunitarios();
      final lista =
          datos.map((j) => PuntoComunitario.fromJson(j)).toList();
      if (!mounted) return;
      setState(() => _puntosComunitarios = lista);
      // Corregimos las posiciones (pegarlas a la calle) despues de mostrarlas.
      // Los marcadores aparecen enseguida y luego "saltan" a la calle real.
      _corregirPosiciones(lista);
    } catch (e) {
      // No hay backend o fallo la carga: simplemente no mostramos puntos
      if (!mounted) return;
      // Aviso suave para el usuario (opcional)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar los puntos de la comunidad'),
        ),
      );
    }
  }

  // Devuelve los puntos oficiales aplicando busqueda, filtro por categoria y orden.
  List<PuntoAcopio> get _puntosFiltrados {
    // Partimos con la lista completa de puntos oficiales
    List<PuntoAcopio> lista = List.from(puntosAcopio);

    // (1) Filtro por texto: el nombre o la direccion contienen lo buscado.
    // Solo se aplica cuando NO hay una busqueda de direccion activa, para que
    // el punto mas cercano y todos los marcadores queden visibles.
    if (_busqueda.isNotEmpty && _ubicacionUsuario == null) {
      final q = _busqueda.toLowerCase();
      lista = lista
          .where((p) =>
              p.nombre.toLowerCase().contains(q) ||
              p.direccion.toLowerCase().contains(q))
          .toList();
    }

    // (2) Orden alfabetico por nombre (A-Z o Z-A)
    lista.sort((a, b) => _orden == 'nombre_az'
        ? a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase())
        : b.nombre.toLowerCase().compareTo(a.nombre.toLowerCase()));

    return lista;
  }

  // ─────────────────────────────────────────────────────────────
  //  BUSCAR DIRECCION → RUTA AL PUNTO DE RECOLECCION MAS CERCANO
  // ─────────────────────────────────────────────────────────────

  // Convierte un color hexadecimal (ej: "#00AEEF") a un Color de Flutter.
  // Los colores de los cuadrantes vienen como texto hex desde los datos
  // oficiales, y Flutter necesita un objeto Color para pintarlos.
  Color _colorDesdeHex(String hex) {
    // Quitamos el '#' inicial si lo trae
    var limpio = hex.replaceAll('#', '').trim();
    // Si viene sin transparencia (6 digitos), le anteponemos 'FF' (opaco)
    if (limpio.length == 6) limpio = 'FF$limpio';
    // int.parse en base 16 convierte el texto hex a numero, y con eso Color
    return Color(int.parse(limpio, radix: 16));
  }

  // Convierte grados a radianes (seno/coseno de Dart trabajan en radianes).
  double _gradosARadianes(double grados) => grados * (pi / 180);

  // Distancia REAL en metros entre dos coordenadas usando Haversine.
  // Sirve para saber que punto de recoleccion esta mas cerca de la casa.
  double _haversineMetros(LatLng a, LatLng b) {
    const double radioTierra = 6371000; // radio de la Tierra en metros
    final double dLat = _gradosARadianes(b.latitude - a.latitude);
    final double dLng = _gradosARadianes(b.longitude - a.longitude);
    final double h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(a.latitude)) *
            cos(_gradosARadianes(b.latitude)) *
            sin(dLng / 2) * sin(dLng / 2);
    return radioTierra * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  // Da formato bonito a la distancia: metros si es corta, km si pasa de 1000.
  String _formatoDistancia(double metros) {
    if (metros >= 1000) return '${(metros / 1000).toStringAsFixed(1)} km';
    return '${metros.round()} metros';
  }

  // Se ejecuta cuando el usuario busca su direccion en la barra de arriba.
  // Geocodifica la direccion, busca el punto de recoleccion mas cercano y
  // dibuja la ruta que sigue las calles hasta el.
  Future<void> _buscarDireccion(String texto) async {
    final direccion = texto.trim();
    if (direccion.isEmpty) return;

    // Ocultamos el teclado y encendemos el indicador de carga
    FocusScope.of(context).unfocus();
    setState(() => _buscando = true);

    try {
      // (1) Pedimos las coordenadas de la direccion (geocoding con Nominatim)
      final coords = await ApiService.buscarCoordenadas(direccion);
      // Tras el await revisamos que la pantalla siga viva antes de usar context
      // (evita el error _dependents.isEmpty si el usuario ya cambio de pantalla).
      if (!mounted) return;

      // No se encontro la direccion: aviso naranja y salimos
      if (coords == null) {
        setState(() => _buscando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró esa dirección en Arica'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // (2) Ubicacion de la casa del usuario
      final usuario = LatLng(coords['lat']!, coords['lng']!);

      // (3) Buscamos el punto de recoleccion MAS CERCANO con Haversine.
      // Recorremos SOLO los puntos visibles (los que pasan el filtro), asi:
      //  - Si el usuario acaba de crear un punto cercano, tambien lo considera.
      //  - Si hay un filtro por tipo activo, solo mira los de ese tipo.
      final visibles = _recoleccionVisibles;
      if (visibles.isEmpty) {
        setState(() => _buscando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay puntos de recolección para mostrar la ruta'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      PuntoComunitario? masCercano;
      double menorDistancia = double.infinity;
      for (final p in visibles) {
        // Medimos hasta la posicion corregida (la que se ve en el mapa)
        final d = _haversineMetros(usuario, _posDe(p));
        if (d < menorDistancia) {
          menorDistancia = d;
          masCercano = p;
        }
      }

      // (4) Le pedimos a OSRM la ruta por las calles hasta ese punto.
      final destino = _posDe(masCercano!);
      final ruta = await ApiService.obtenerRuta(usuario, destino);
      if (!mounted) return;

      // Si OSRM no devolvio ruta, usamos una linea recta como respaldo.
      final rutaFinal = ruta.isNotEmpty ? ruta : [usuario, destino];

      setState(() {
        _ubicacionUsuario = usuario;
        _resultado = _ResultadoRuta(
          punto: masCercano!,
          distanciaMetros: menorDistancia,
          ruta: rutaFinal,
        );
        _buscando = false;
      });

      // (5) Ajustamos el zoom para que se vea TODA la ruta en pantalla.
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(rutaFinal),
          padding: const EdgeInsets.all(60),
        ),
      );
    } catch (e) {
      // Error de conexion u otro: aviso naranja
      if (!mounted) return;
      setState(() => _buscando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Limpia la busqueda: quita el marcador azul, la ruta y la tarjeta,
  // y regresa el mapa a la vista general de Arica.
  void _limpiarBusqueda() {
    setState(() {
      _busquedaCtrl.clear();
      _busqueda = '';
      _ubicacionUsuario = null;
      _resultado = null;
    });
    _mapController.move(_centroArica, 14);
  }

  // Construye un marcador del mapa. Si "resaltado" es true (es el punto mas
  // cercano a la busqueda), lo dibujamos mas grande y con un circulo de
  // color alrededor para que destaque.
  Marker _construirMarcador({
    required LatLng punto,
    required Color color,
    required bool resaltado,
    required VoidCallback onTap,
  }) {
    final double tam = resaltado ? 60 : 40;
    return Marker(
      point: punto,
      width: tam,
      height: tam,
      child: GestureDetector(
        onTap: onTap,
        child: resaltado
            // Punto mas cercano: icono grande dentro de un circulo de color
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(60), // color translucido de fondo
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.location_on, color: color, size: 44),
              )
            // Punto normal
            : Icon(Icons.location_on, color: color, size: 36),
      ),
    );
  }

  // Muestra el detalle de un punto limpio oficial (rojo)
  void _mostrarDetallesPunto(PuntoAcopio punto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetPunto(punto: punto),
    );
  }

  // Muestra el detalle de un punto de la comunidad (verde)
  void _mostrarDetallesComunitario(PuntoComunitario punto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetComunitario(punto: punto),
    );
  }

  // Abre el panel para filtrar los puntos por tipo de basura (PARTE D).
  void _abrirFiltro() {
    // Copia temporal: marcamos/desmarcamos aqui y recien al "Aplicar filtro"
    // lo pasamos al estado real del mapa.
    final Set<String> seleccion = Set.from(_tiposSeleccionados);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        // StatefulBuilder permite marcar los checkboxes dentro del panel
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar por tipo de basura',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Un checkbox por cada tipo de residuo
                  ..._tiposResiduo.map(
                    (tipo) => CheckboxListTile(
                      title: Text(tipo),
                      value: seleccion.contains(tipo),
                      activeColor: const Color(0xFFE53935),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (marcado) => setSheetState(() {
                        if (marcado == true) {
                          seleccion.add(tipo);
                        } else {
                          seleccion.remove(tipo);
                        }
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quita el filtro y muestra TODOS los puntos
                      TextButton(
                        onPressed: () {
                          setState(() => _tiposSeleccionados = {});
                          Navigator.pop(context);
                        },
                        child: const Text('Mostrar todos'),
                      ),
                      const Spacer(),
                      // Aplica los tipos elegidos
                      ElevatedButton(
                        onPressed: () {
                          setState(
                              () => _tiposSeleccionados = seleccion);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aplicar filtro'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Quita el filtro por tipo (lo llama la ✕ del chip "Filtrando: ...").
  void _quitarFiltro() {
    setState(() => _tiposSeleccionados = {});
  }

  // Abre el menu para ordenar la lista de puntos
  void _abrirOrden() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('Por nombre (A-Z)'),
            onTap: () {
              setState(() => _orden = 'nombre_az');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('Por nombre (Z-A)'),
            onTap: () {
              setState(() => _orden = 'nombre_za');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Se ejecuta al tocar el boton "+" para agregar un punto
  Future<void> _onAgregarPressed() async {
    final token = await AuthStorage.obtenerToken();
    if (!mounted) return;
    // Sin sesion no se puede agregar
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debes iniciar sesión para agregar un punto de recolección'),
        ),
      );
      return;
    }
    // Activamos el modo "elegir lugar en el mapa"
    setState(() => _modoAgregar = true);
  }

  // Abre el formulario para crear el punto en las coordenadas tocadas.
  //
  // El formulario es un widget aparte (_DialogoNuevoPunto) que maneja SUS
  // PROPIOS controladores de texto y los libera en su dispose(). Aquí solo
  // esperamos el resultado del diálogo: si el usuario tocó "Guardar punto"
  // nos devuelve los datos escritos; si canceló, devuelve null.
  //
  // Toda la parte async (llamar al backend) ocurre DESPUÉS de que el diálogo
  // ya se cerró por completo, usando el contexto de la pantalla principal.
  Future<void> _abrirDialogoNuevoPunto(LatLng coords) async {
    // Salimos del modo agregar apenas el usuario tocó el mapa
    setState(() => _modoAgregar = false);

    // Mostramos el diálogo (le pasamos los tipos disponibles) y esperamos.
    final datos = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _DialogoNuevoPunto(tipos: _tiposResiduo),
    );

    // Si canceló o cerró el diálogo sin guardar, no hacemos nada más.
    if (datos == null) return;

    // El diálogo ya se cerró; revisamos que la pantalla siga viva.
    if (!mounted) return;

    // Guardamos el punto en el backend (contexto de la pantalla principal).
    await _guardarPuntoComunitario(
      datos['nombre']!,
      datos['descripcion']!,
      datos['dias']!,
      datos['tipo']!,
      coords,
    );
  }

  // Guarda el punto comunitario en el backend y actualiza el mapa.
  // Se llama DESPUÉS de cerrar el diálogo, por eso usamos el contexto de la
  // pantalla principal (el del diálogo ya no existe). Guardamos el messenger
  // antes de los await y revisamos "mounted" después de cada uno.
  Future<void> _guardarPuntoComunitario(
    String nombre,
    String descripcion,
    String dias,
    String tipoResiduo,
    LatLng coords,
  ) async {
    // Guardamos el messenger antes de los await para no usar el context
    // después de una operación asíncrona.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await AuthStorage.obtenerToken();
      await ApiService.crearPuntoComunitario(
        nombre,
        descripcion,
        coords.latitude,
        coords.longitude,
        dias,
        tipoResiduo,
        token ?? '',
      );
      // Recargamos la lista para que aparezca el nuevo punto en el mapa
      await _cargarPuntosComunitarios();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('¡Punto agregado! Gracias por ayudar a tu comunidad'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Si algo falla mostramos el error en rojo
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  HU-06: AVISO DE RECOLECCION DE HOY
  // ─────────────────────────────────────────────────────────────

  // Devuelve el nombre del día de hoy en español, tal como aparece escrito
  // en los datos de los cuadrantes (con tildes: "Miércoles", "Sábado").
  String _nombreDiaHoy() {
    // DateTime.now().weekday: 1 = lunes ... 7 = domingo.
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return dias[DateTime.now().weekday - 1];
  }

  // Devuelve la lista de cuadrantes NOCTURNOS que tienen recolección hoy.
  // Recorre todos los cuadrantes y se queda con los que:
  //  - son de jornada "Nocturna", y
  //  - sus días de recolección incluyen el día de hoy.
  List<Cuadrante> _cuadrantesConRecoleccionHoy() {
    final hoy = _nombreDiaHoy();
    return cuadrantesArica
        .where((c) =>
            c.jornada == 'Nocturna' && c.diasRecoleccion.contains(hoy))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos (una vez por build) qué cuadrantes tienen recolección hoy.
    final cuadrantesHoy = _cuadrantesConRecoleccionHoy();

    return Scaffold(
      body: Stack(
        children: [
          // Capa principal del mapa OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroArica,
              initialZoom: 14,
              // Si estamos en modo agregar, al tocar el mapa abrimos el formulario
              onTap: (tapPosition, LatLng punto) {
                if (_modoAgregar) _abrirDialogoNuevoPunto(punto);
              },
            ),
            children: [
              // PASO 5: mapa base con el estilo limpio CartoDB Positron,
              // el mismo que usa el mapa oficial de la municipalidad.
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.trashgo.app',
                maxZoom: 19,
              ),
              // Dibujamos TODOS los cuadrantes oficiales como poligonos.
              // Va ANTES de los marcadores para que las zonas queden por debajo.
              PolygonLayer(
                polygons: cuadrantesArica.map((c) {
                  final color = _colorDesdeHex(c.color);
                  return Polygon(
                    points: c.puntos,
                    borderColor: color,
                    borderStrokeWidth: 2,
                    // isFilled: true hace que se pinte el relleno del poligono
                    isFilled: true,
                    // withValues(alpha:) da el nivel de transparencia del relleno
                    color: color.withValues(alpha: 0.18),
                  );
                }).toList(),
              ),
              // PASO 4: ruta azul (siguiendo las calles) desde la casa del
              // usuario hasta el punto de recoleccion mas cercano. Va sobre los
              // poligonos pero debajo de los marcadores.
              if (_resultado != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _resultado!.ruta,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              // Marcadores de puntos limpios oficiales (rojos, ya filtrados).
              MarkerLayer(
                markers: _puntosFiltrados
                    .map(
                      (p) => _construirMarcador(
                        punto: LatLng(p.latitud, p.longitud),
                        color: Colors.red,
                        resaltado: false,
                        onTap: () => _mostrarDetallesPunto(p),
                      ),
                    )
                    .toList(),
              ),
              // Marcadores VERDES de TODOS los puntos de recoleccion del backend
              // (los 31 oficiales + los que agregan los usuarios). Se muestran
              // igual, sin diferencia visual, y respetando el filtro por tipo.
              MarkerLayer(
                markers: _recoleccionVisibles
                    .map(
                      (p) => _construirMarcador(
                        // Usamos la posicion corregida (pegada a la calle)
                        punto: _posDe(p),
                        color: Colors.green,
                        resaltado: false,
                        onTap: () => _mostrarDetallesComunitario(p),
                      ),
                    )
                    .toList(),
              ),
              // Marcador de ubicación simulada del usuario (punto celeste)
              const MarkerLayer(
                markers: [
                  Marker(
                    point: _centroArica,
                    width: 24,
                    height: 24,
                    child: _UbicacionUsuario(),
                  ),
                ],
              ),
              // Marcador AZUL de la direccion que busco el usuario
              if (_ubicacionUsuario != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionUsuario!,
                      width: 120,
                      height: 70,
                      child: const _MarcadorUsuario(),
                    ),
                  ],
                ),
            ],
          ),
          // Barra de búsqueda y filtros flotante sobre el mapa
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _BarraBusqueda(
              controller: _busquedaCtrl,
              buscando: _buscando,
              mostrarLimpiar: _ubicacionUsuario != null,
              tiposActivos: _tiposSeleccionados.toList(),
              onChanged: (valor) => setState(() => _busqueda = valor),
              onSubmitted: _buscarDireccion,
              onLimpiar: _limpiarBusqueda,
              onFiltro: _abrirFiltro,
              onOrden: _abrirOrden,
              onQuitarFiltro: _quitarFiltro,
            ),
          ),
          // Banner que aparece cuando el usuario esta eligiendo un lugar
          if (_modoAgregar)
            Positioned(
              top: 160,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Toca en el mapa el lugar del punto de recolección',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    // La X cancela el modo agregar
                    GestureDetector(
                      onTap: () => setState(() => _modoAgregar = false),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          // HU-06: aviso de recolección de hoy. Aparece arriba, se puede
          // cerrar con la X, y no se muestra mientras se agrega un punto.
          if (_mostrarAvisoRecoleccion && !_modoAgregar)
            Positioned(
              top: 150,
              left: 16,
              right: 16,
              child: _AvisoRecoleccion(
                cuadrantesHoy: cuadrantesHoy,
                onCerrar: () =>
                    setState(() => _mostrarAvisoRecoleccion = false),
              ),
            ),
          // Leyenda de colores abajo a la izquierda.
          // La ocultamos cuando mostramos la tarjeta de la ruta encontrada.
          if (_resultado == null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Card(
                color: const Color.fromARGB(230, 255, 255, 255),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _FilaLeyenda(
                        color: Colors.red,
                        texto: 'Puntos limpios oficiales',
                      ),
                      SizedBox(height: 4),
                      _FilaLeyenda(
                        color: Colors.green,
                        texto: 'Puntos de recolección',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Tarjeta inferior con el punto de recoleccion mas cercano y su ruta
          if (_resultado != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _TarjetaRuta(
                resultado: _resultado!,
                distanciaTexto: _formatoDistancia(_resultado!.distanciaMetros),
                onCerrar: _limpiarBusqueda,
              ),
            ),
        ],
      ),
      // Boton flotante para agregar un punto de la comunidad
      floatingActionButton: FloatingActionButton(
        onPressed: _onAgregarPressed,
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        tooltip: 'Agregar punto',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const BottomNav(indiceSeleccionado: 1),
    );
  }
}

// Indicador de posición del usuario (punto celeste con halo)
class _UbicacionUsuario extends StatelessWidget {
  const _UbicacionUsuario();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(102, 3, 169, 244),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.lightBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(102, 3, 169, 244),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: CircleAvatar(
              radius: 3,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Fila de la leyenda: un punto de color + su texto
class _FilaLeyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _FilaLeyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 16),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Barra de búsqueda y filtros flotante
class _BarraBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final bool buscando; // true = mostrar circulito de carga
  final bool mostrarLimpiar; // true = mostrar la X para limpiar
  final List<String> tiposActivos; // tipos del filtro activo (vacio = sin filtro)
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted; // al presionar buscar/enter
  final VoidCallback onLimpiar;
  final VoidCallback onFiltro;
  final VoidCallback onOrden;
  final VoidCallback onQuitarFiltro; // ✕ del chip "Filtrando: ..."

  const _BarraBusqueda({
    required this.controller,
    required this.buscando,
    required this.mostrarLimpiar,
    required this.tiposActivos,
    required this.onChanged,
    required this.onSubmitted,
    required this.onLimpiar,
    required this.onFiltro,
    required this.onOrden,
    required this.onQuitarFiltro,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(38, 0, 0, 0),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // Campo de texto real para buscar la direccion del usuario
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            // Al presionar "buscar" en el teclado, geocodificamos la direccion
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Escribe tu dirección',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              // El icono de la derecha cambia segun el estado:
              suffixIcon: buscando
                  // Buscando: mostramos el circulito de carga
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : mostrarLimpiar
                      // Hay un resultado: mostramos la X para limpiar
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: onLimpiar,
                        )
                      // Sin resultado: boton rojo para lanzar la busqueda
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward,
                              color: Color(0xFFE53935)),
                          onPressed: () => onSubmitted(controller.text),
                        ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Chip que abre el panel de filtros
            _ChipFiltro(texto: 'Filtro ▾', onTap: onFiltro),
            const SizedBox(width: 8),
            // Chip que abre el menu de orden
            _ChipFiltro(texto: 'Ordenar ▾', onTap: onOrden),
          ],
        ),
        // PARTE D4: cuando hay filtro activo, mostramos un chip rojo con los
        // tipos elegidos y una ✕ para quitar el filtro.
        if (tiposActivos.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onQuitarFiltro,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Filtrando: ${tiposActivos.join(', ')}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.close, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _ChipFiltro({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(20, 0, 0, 0),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(texto, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

// Bottom sheet con detalles de un punto limpio oficial (rojo).
// Solo muestra informacion: nombre, direccion, tipo de residuo y horario.
class _BottomSheetPunto extends StatelessWidget {
  final PuntoAcopio punto;
  const _BottomSheetPunto({required this.punto});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE53935);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del punto
          Text(
            punto.nombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Direccion
          _InfoRow(
            icon: Icons.location_on,
            iconColor: accentColor,
            text: punto.direccion,
          ),
          const SizedBox(height: 8),
          // Tipo de residuo que acepta
          _InfoRow(
            icon: Icons.recycling,
            iconColor: Colors.green.shade600,
            text: punto.tipoResiduo,
          ),
          const SizedBox(height: 8),
          // Horario
          _InfoRow(
            icon: Icons.access_time,
            iconColor: Colors.blueGrey,
            text: punto.horario,
          ),
        ],
      ),
    );
  }
}

// Bottom sheet con detalles de un punto de recoleccion (PARTE B3).
// Muestra: nombre, sector, dias, horario y el tipo de residuo que acepta.
class _BottomSheetComunitario extends StatelessWidget {
  final PuntoComunitario punto;
  const _BottomSheetComunitario({required this.punto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del punto
          Text(
            punto.nombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          // Sector / cuadrante (solo si tiene)
          if (punto.sector.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.map_outlined,
              iconColor: Colors.green,
              text: 'Sector: ${punto.sector}',
            ),
          ],
          // Dias de recoleccion (solo si tiene)
          if (punto.diasRecoleccion.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.local_shipping,
              iconColor: Colors.blueGrey,
              text: 'Días de recolección: ${punto.diasRecoleccion}',
            ),
          ],
          // Horario (solo si tiene)
          if (punto.horario.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time,
              iconColor: Colors.blueGrey,
              text: 'Horario: ${punto.horario}',
            ),
          ],
          // Tipo de residuo que acepta (solo si tiene)
          if (punto.tipoResiduo.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.recycling,
              iconColor: Colors.green,
              text: 'Acepta: ${punto.tipoResiduo}',
            ),
          ],
          const SizedBox(height: 16),
          // Nombre de quien agrego el punto (Municipalidad si es oficial)
          Text(
            'Agregado por: ${punto.autorNombre}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// Formulario (diálogo) para crear un punto de la comunidad.
//
// Es un StatefulWidget APARTE que maneja sus propios controladores de texto
// y los libera en su propio dispose(). Esto evita el error
// "_dependents.isEmpty": los controladores se liberan solo cuando el diálogo
// se desmonta de verdad, nunca "a mano" mientras los TextField siguen vivos.
//
// El diálogo NO llama al backend ni toca el estado del mapa. Solo valida y,
// al guardar, se cierra devolviendo los datos escritos con Navigator.pop.
class _DialogoNuevoPunto extends StatefulWidget {
  // Lista de tipos de residuo disponibles para elegir (viene del mapa).
  final List<String> tipos;
  const _DialogoNuevoPunto({required this.tipos});

  @override
  State<_DialogoNuevoPunto> createState() => _DialogoNuevoPuntoState();
}

class _DialogoNuevoPuntoState extends State<_DialogoNuevoPunto> {
  // Controladores propios de este diálogo
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _diasCtrl = TextEditingController();

  // Tipo de residuo elegido en el menu desplegable (empieza en null = sin elegir)
  String? _tipoElegido;

  @override
  void dispose() {
    // Se liberan cuando el diálogo se cierra de verdad (forma segura)
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _diasCtrl.dispose();
    super.dispose();
  }

  // Al tocar "Guardar punto": validamos y devolvemos los datos al mapa.
  void _guardar() {
    final nombre = _nombreCtrl.text.trim();
    // El nombre es obligatorio
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del lugar')),
      );
      return;
    }
    // El tipo de residuo tambien es obligatorio
    if (_tipoElegido == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige el tipo de basura que acepta')),
      );
      return;
    }
    // Cerramos el diálogo devolviendo lo que escribió el usuario.
    // El mapa recibe este Map y se encarga de llamar al backend.
    Navigator.pop(context, {
      'nombre': nombre,
      'descripcion': _descCtrl.text.trim(),
      'dias': _diasCtrl.text.trim(),
      'tipo': _tipoElegido!,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo punto de recolección'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del lugar',
              ),
            ),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción/referencia',
              ),
            ),
            TextField(
              controller: _diasCtrl,
              decoration: const InputDecoration(
                labelText: 'Días que pasa el camión',
              ),
            ),
            const SizedBox(height: 8),
            // Menu desplegable para elegir el tipo de basura que acepta
            DropdownButtonFormField<String>(
              initialValue: _tipoElegido,
              decoration: const InputDecoration(
                labelText: 'Tipo de basura que acepta',
              ),
              items: widget.tipos
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (valor) => setState(() => _tipoElegido = valor),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          // Cerrar sin guardar: devuelve null
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          child: const Text('Guardar punto'),
        ),
      ],
    );
  }
}

// Marcador AZUL con la etiqueta "Tú estás aquí".
// Muestra la ubicacion de la direccion que busco el usuario.
class _MarcadorUsuario extends StatelessWidget {
  const _MarcadorUsuario();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiqueta arriba del pin
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Tú estás aquí',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        // Pin azul de ubicacion (distinto de los rojos y verdes)
        const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
      ],
    );
  }
}

// Tarjeta inferior que muestra el punto de recoleccion mas cercano encontrado
// por la busqueda, con la distancia, los dias y el horario de recoleccion.
class _TarjetaRuta extends StatelessWidget {
  final _ResultadoRuta resultado;
  final String distanciaTexto;
  final VoidCallback onCerrar;

  const _TarjetaRuta({
    required this.resultado,
    required this.distanciaTexto,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final punto = resultado.punto;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titulo con el nombre del punto y la X para cerrar
            Row(
              children: [
                Expanded(
                  child: Text(
                    '📍 Punto más cercano: ${punto.nombre}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onCerrar,
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Distancia hasta el punto (en linea recta)
            _FilaEmoji(emoji: '📏', texto: 'A $distanciaTexto de tu ubicación'),
            const SizedBox(height: 6),
            // Dias de recoleccion
            _FilaEmoji(
              emoji: '🗓️',
              texto: 'Días de recolección: ${punto.diasRecoleccion}',
            ),
            const SizedBox(height: 6),
            // Horario
            _FilaEmoji(emoji: '🕘', texto: 'Horario: ${punto.horario}'),
          ],
        ),
      ),
    );
  }
}

// Una fila con un emoji + su texto (se usa en la tarjeta de resultado).
class _FilaEmoji extends StatelessWidget {
  final String emoji;
  final String texto;

  const _FilaEmoji({required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

// HU-06: tarjeta de aviso que dice si hoy pasa el camión de la basura.
// Si hay cuadrantes con recolección hoy, muestra la lista en un aviso rojo.
// Si no hay ninguno, muestra un aviso gris de "hoy no hay recolección".
class _AvisoRecoleccion extends StatelessWidget {
  final List<Cuadrante> cuadrantesHoy;
  final VoidCallback onCerrar;

  const _AvisoRecoleccion({
    required this.cuadrantesHoy,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    // ¿Hay recolección nocturna hoy?
    final hayRecoleccion = cuadrantesHoy.isNotEmpty;

    // Armamos la lista de nombres de los cuadrantes para el mensaje.
    final nombres = cuadrantesHoy.map((c) => c.nombre).join(', ');

    // Elegimos color y texto según haya o no recolección hoy.
    final color = hayRecoleccion ? const Color(0xFFE53935) : Colors.blueGrey;
    final texto = hayRecoleccion
        ? '🚛 Hoy pasa el camión en los cuadrantes $nombres desde las '
            '21:00 h. ¡No olvides sacar tu basura!'
        : 'Hoy no hay recolección nocturna programada';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(50, 0, 0, 0),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          // La X cierra el aviso.
          GestureDetector(
            onTap: onCerrar,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// Guarda el resultado de la busqueda: el punto de recoleccion mas cercano,
// la distancia en metros hasta el y la ruta (lista de puntos) por las calles.
class _ResultadoRuta {
  final PuntoComunitario punto;
  final double distanciaMetros;
  final List<LatLng> ruta;

  _ResultadoRuta({
    required this.punto,
    required this.distanciaMetros,
    required this.ruta,
  });
}
