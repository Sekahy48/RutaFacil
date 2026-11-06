// Datos de EJEMPLO inventados para la zona de prueba (tipo León).
// No son datos reales: sin tiempo real, horarios teóricos.

import 'package:latlong2/latlong.dart';

/// Si es `true` (por defecto), la app usa siempre [kHoraReferenciaFija] como
/// "ahora", para que las pruebas y capturas sean reproducibles.
/// Si es `false`, usa la hora actual del dispositivo.
const bool kUsarHoraFija = true;

/// Hora de referencia fija, en minutos desde las 00:00 (08:30).
const int kHoraReferenciaFija = 8 * 60 + 30;

/// Fin del servicio: no hay salidas desde cabecera después de esta hora.
const int kFinServicio = 22 * 60;

/// Minutos desde las 00:00 que se usan como "ahora".
int minutoReferencia() {
  if (kUsarHoraFija) return kHoraReferenciaFija;
  final ahora = DateTime.now();
  return ahora.hour * 60 + ahora.minute;
}

/// Formatea minutos desde las 00:00 como "hh:mm".
String hhmm(int minutos) {
  final h = (minutos ~/ 60) % 24;
  final m = minutos % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class Parada {
  const Parada(this.id, this.nombre, this.posicion);
  final String id;
  final String nombre;
  final LatLng posicion;
}

class Linea {
  const Linea({
    required this.id,
    required this.nombre,
    required this.paradas,
    required this.offsets,
    required this.primeraSalida,
    required this.frecuencia,
    required this.resumen,
  });

  final String id;

  /// Nombre visible, p. ej. "Línea 1".
  final String nombre;

  /// Ids de parada en orden de recorrido (un solo sentido).
  final List<String> paradas;

  /// Minutos desde la salida de cabecera hasta cada parada.
  final List<int> offsets;

  /// Primera salida desde cabecera (minutos desde las 00:00).
  final int primeraSalida;

  /// Minutos entre salidas.
  final int frecuencia;

  /// Recorrido resumido para la lista de líneas.
  final String resumen;

  String get destino => paradaPorId(paradas.last).nombre;

  /// Salidas desde cabecera durante el día de servicio.
  Iterable<int> get salidas sync* {
    for (var t = primeraSalida; t <= kFinServicio; t += frecuencia) {
      yield t;
    }
  }

  /// Horas de paso por la parada en la posición [indice], desde [desde].
  List<int> pasosPor(int indice, {required int desde, int maximo = 3}) {
    final res = <int>[];
    for (final s in salidas) {
      final t = s + offsets[indice];
      if (t >= desde) res.add(t);
      if (res.length == maximo) break;
    }
    return res;
  }
}

// Coordenadas inventadas (~2 km alrededor del centro de León), con las
// posiciones relativas del wireframe P6: Estación arriba-izquierda,
// Hospital abajo-derecha.
const List<Parada> kParadas = [
  Parada('estacion', 'Estación', LatLng(42.6077, -5.5771)),
  Parada('guzman', 'Guzmán', LatLng(42.6069, -5.5637)),
  Parada('catedral', 'Catedral', LatLng(42.6030, -5.5710)),
  Parada('sanmarcos', 'San Marcos', LatLng(42.6000, -5.5609)),
  Parada('universidad', 'Universidad', LatLng(42.5975, -5.5771)),
  Parada('hospital', 'Hospital', LatLng(42.5944, -5.5659)),
  Parada('quevedo', 'Quevedo', LatLng(42.5925, -5.5795)),
];

const List<Linea> kLineas = [
  Linea(
    id: 'L1',
    nombre: 'Línea 1',
    paradas: [
      'estacion',
      'guzman',
      'catedral',
      'sanmarcos',
      'universidad',
      'hospital',
    ],
    offsets: [0, 4, 7, 11, 16, 20],
    primeraSalida: 8 * 60 + 5,
    frecuencia: 15,
    resumen: 'Estación – Hospital (por Catedral)',
  ),
  Linea(
    id: 'L2',
    nombre: 'Línea 2',
    paradas: ['estacion', 'guzman', 'sanmarcos', 'hospital'],
    offsets: [0, 6, 12, 22],
    primeraSalida: 8 * 60 + 10,
    frecuencia: 20,
    resumen: 'Estación – Hospital (por San Marcos)',
  ),
  Linea(
    id: 'L3',
    nombre: 'Línea 3',
    paradas: ['estacion', 'guzman', 'catedral', 'universidad'],
    offsets: [0, 5, 9, 17],
    primeraSalida: 8 * 60 + 3,
    frecuencia: 20,
    resumen: 'Estación – Universidad (por Catedral)',
  ),
  Linea(
    id: 'L4',
    nombre: 'Línea 4',
    paradas: ['quevedo', 'universidad', 'hospital'],
    offsets: [0, 8, 12],
    primeraSalida: 8 * 60 + 20,
    frecuencia: 30,
    resumen: 'Quevedo – Hospital (por Universidad)',
  ),
];

Parada paradaPorId(String id) => kParadas.firstWhere((p) => p.id == id);

/// Líneas que pasan por la parada [id].
List<Linea> lineasDeParada(String id) =>
    kLineas.where((l) => l.paradas.contains(id)).toList();

/// Paradas ordenadas alfabéticamente (para listas).
List<Parada> paradasOrdenadas() {
  final lista = [...kParadas];
  lista.sort((a, b) => normalizar(a.nombre).compareTo(normalizar(b.nombre)));
  return lista;
}

/// Minúsculas y sin tildes, para buscar sin importar acentos.
String normalizar(String texto) {
  const con = 'áàäâéèëêíìïîóòöôúùüû';
  const sin = 'aaaaeeeeiiiioooouuuu';
  final b = StringBuffer();
  for (final c in texto.toLowerCase().trim().split('')) {
    final i = con.indexOf(c);
    b.write(i >= 0 ? sin[i] : c);
  }
  return b.toString();
}

/// Paradas cuyo nombre contiene [texto] (sin importar tildes).
List<Parada> buscarParadas(String texto) {
  final q = normalizar(texto);
  return paradasOrdenadas()
      .where((p) => q.isEmpty || normalizar(p.nombre).contains(q))
      .toList();
}

/// Parada cuyo nombre coincide exactamente con [texto] (sin tildes), o null.
Parada? paradaPorNombre(String texto) {
  final q = normalizar(texto);
  for (final p in kParadas) {
    if (normalizar(p.nombre) == q) return p;
  }
  return null;
}
