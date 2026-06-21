import 'package:latlong2/latlong.dart';
import '../models/cuadrante.dart';
import '../models/punto_acopio.dart';
import '../models/foro.dart';

// Cuadrantes de recolección de Arica con coordenadas reales aproximadas
final List<Cuadrante> cuadrantes = [
  Cuadrante(
    id: '1',
    nombre: 'Cuadrante 1 - Norte',
    numero: 1,
    diasRecoleccion: 'Mar/Jue/Dom',
    hora: '21:00',
    puntos: [
      LatLng(-18.465, -70.315),
      LatLng(-18.470, -70.308),
      LatLng(-18.475, -70.312),
      LatLng(-18.468, -70.320),
    ],
  ),
  Cuadrante(
    id: '2',
    nombre: 'Cuadrante 2 - Centro Norte',
    numero: 2,
    diasRecoleccion: 'Mar/Jue/Dom',
    hora: '21:00',
    puntos: [
      LatLng(-18.472, -70.320),
      LatLng(-18.478, -70.315),
      LatLng(-18.480, -70.308),
      LatLng(-18.475, -70.302),
    ],
  ),
  Cuadrante(
    id: '3',
    nombre: 'Cuadrante 3 - Centro',
    numero: 3,
    diasRecoleccion: 'Lun/Mié/Vie',
    hora: '21:00',
    puntos: [
      LatLng(-18.478, -70.318),
      LatLng(-18.483, -70.312),
      LatLng(-18.486, -70.306),
      LatLng(-18.480, -70.300),
    ],
  ),
  Cuadrante(
    id: '4',
    nombre: 'Cuadrante 4 - Centro Sur',
    numero: 4,
    diasRecoleccion: 'Lun/Mié/Vie',
    hora: '21:00',
    puntos: [
      LatLng(-18.484, -70.316),
      LatLng(-18.489, -70.310),
      LatLng(-18.492, -70.303),
      LatLng(-18.486, -70.297),
    ],
  ),
];

// Puntos de acopio reales de la ciudad de Arica
final List<PuntoAcopio> puntosAcopio = [
  PuntoAcopio(
    id: '1',
    nombre: 'Punto Acopio 21 de Mayo',
    direccion: '21 de Mayo 230, Arica',
    latitud: -18.4751,
    longitud: -70.3132,
    tipoResiduo: 'Orgánico',
  ),
  PuntoAcopio(
    id: '2',
    nombre: 'Punto Acopio Chacabuco',
    direccion: 'Chacabuco 456, Arica',
    latitud: -18.4780,
    longitud: -70.3098,
    tipoResiduo: 'Plástico',
  ),
  PuntoAcopio(
    id: '3',
    nombre: 'Punto Acopio Sotomayor',
    direccion: 'Sotomayor 123, Arica',
    latitud: -18.4812,
    longitud: -70.3145,
    tipoResiduo: 'Vidrio',
  ),
  PuntoAcopio(
    id: '4',
    nombre: 'Punto Acopio Baquedano',
    direccion: 'Baquedano 890, Arica',
    latitud: -18.4765,
    longitud: -70.3067,
    tipoResiduo: 'Orgánico',
  ),
  PuntoAcopio(
    id: '5',
    nombre: 'Punto Acopio Lynch',
    direccion: 'Lynch 567, Arica',
    latitud: -18.4798,
    longitud: -70.3115,
    tipoResiduo: 'Plástico',
  ),
];

// Foros de la comunidad
final List<Foro> foros = [
  Foro(
    id: '1',
    nombre: 'Basura en calle Lynch',
    ultimoMensaje: 'Vecinos reportan acumulación de basura',
    fecha: 'Hoy 21:00',
  ),
  Foro(
    id: '2',
    nombre: 'Camión no pasó el martes',
    ultimoMensaje: '¿A alguien más no le pasaron?',
    fecha: 'Ayer',
  ),
  Foro(
    id: '3',
    nombre: 'Horarios sector norte',
    ultimoMensaje: 'Confirman nuevo horario para cuadrante 1',
    fecha: 'Lunes',
  ),
  Foro(
    id: '4',
    nombre: 'Punto de acopio lleno',
    ultimoMensaje: 'El punto de 21 de Mayo está saturado',
    fecha: 'Domingo',
  ),
  Foro(
    id: '5',
    nombre: 'Felicitaciones municipio',
    ultimoMensaje: 'Esta semana pasaron puntual todos los días',
    fecha: 'Sábado',
  ),
];

// Mensajes del foro "Basura en calle Lynch"
final List<MensajeForo> mensajesLynch = [
  MensajeForo(
    id: '1',
    contenido: 'Vi que hay basura acumulada desde ayer',
    autor: 'María G.',
    esMio: false,
    hora: '20:15',
  ),
  MensajeForo(
    id: '2',
    contenido: 'Sí, el camión no pasó el martes',
    autor: 'Carlos R.',
    esMio: false,
    hora: '20:18',
  ),
  MensajeForo(
    id: '3',
    contenido: 'Voy a reportarlo a la municipalidad',
    autor: '',
    esMio: true,
    hora: '20:20',
  ),
  MensajeForo(
    id: '4',
    contenido: 'Gracias, ojalá vengan pronto',
    autor: 'María G.',
    esMio: false,
    hora: '20:22',
  ),
];
