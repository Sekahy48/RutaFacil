// Datos reales sacados de OpenStreetMap

import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Si es `true` , la app usa siempre [kHoraReferenciaFija] como
/// "ahora", para que las pruebas y capturas sean reproducibles.
/// Si es `false`, usa la hora actual del dispositivo.
const bool kUsarHoraFija = false;

/// Hora de referencia fija, en minutos desde las 00:00 (08:30).
const int kHoraReferenciaFija = 8 * 60 + 30;

/// Fin del servicio: no hay salidas desde cabecera después de esta hora.
const int kFinServicio = 22 * 60;

// PROVISIONAL: hasta tener horarios reales.
const int kPrimeraSalidaDefecto = 7 * 60;   // 07:00
const int kFrecuenciaDefecto = 20;          // min
const int kMinPorParadaDefecto = 2;         // min entre paradas

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
  const Parada(this.id, this.nombre, this.posicion,
      {this.wheelchair, this.tactilePaving, this.shelter, this.bench});
  final String id;
  final String nombre;
  final LatLng posicion;
  final String? wheelchair, tactilePaving, shelter, bench;

  factory Parada.fromJson(Map<String, dynamic> j) => Parada(
        j['id'] as String,
        (j['nombre'] as String?) ?? (j['ref'] as String?) ?? 'Parada sin nombre',
        LatLng((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble()),
        wheelchair: j['wheelchair'] as String?,
        tactilePaving: j['tactile_paving'] as String?,
        shelter: j['shelter'] as String?,
        bench: j['bench'] as String?,
      );
}

class Linea {
  Linea({
    required this.id,
    required this.ref,
    required this.resumen,
    required this.origen,
    required this.destinoJson,   
    required this.paradas,
    required this.incompleta,
    required this.horarios,
  });

  final String id; // único: ref#n
  final String ref;
  final String resumen; // "1: Armunia → Hospitales"
  final String origen;
  final String destinoJson;
  final List<String> paradas; // solo ids existentes
  final bool incompleta;
  final dynamic horarios; // null por ahora

  String get nombre => 'Línea $ref';
  String get destino =>
      destinoJson.isNotEmpty ? destinoJson : paradaPorId(paradas.last).nombre;

  bool get horarioEsDefecto => horarios == null;

  // PROVISIONAL hasta horarios reales
  int get primeraSalida => kPrimeraSalidaDefecto;
  int get frecuencia => kFrecuenciaDefecto;
  List<int> get offsets =>
      [for (var i = 0; i < paradas.length; i++) i * kMinPorParadaDefecto];

  Iterable<int> get salidas sync* {
    for (var t = primeraSalida; t <= kFinServicio; t += frecuencia) {
      yield t;
    }
  }

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
List<Parada> kParadas = [];
List<Linea> kLineas = [];
Map<String, Parada> _paradasPorId = {};

Parada paradaPorId(String id) => _paradasPorId[id]!;

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

Future<void> cargarDatos() async {
  final paradas = await rootBundle.loadString('assets/data/paradas.json');
  final lineas = await rootBundle.loadString('assets/data/lineas.json');
  final p = json.decode(paradas) as Map<String, dynamic>;
  final l = json.decode(lineas) as Map<String, dynamic>;
  kParadas = (p['paradas'] as List)
    .map((e) => Parada.fromJson(e as Map<String, dynamic>))
    .toList();
_paradasPorId = {for (final x in kParadas) x.id: x};
  kLineas = [];
for (final e in (l['lineas'] as List)) {
  final ref = (e['ref'] as String?) ?? '?';
  var n = 0;
  for (final v in (e['variantes'] as List)) {
    final ids = (v['paradas'] as List)
        .cast<String>()
        .where(_paradasPorId.containsKey)
        .toList();
    if (ids.length < 2) continue; // variante inútil
    kLineas.add(Linea(
      id: '$ref#${n++}',
      ref: ref,
      resumen: (v['nombre'] as String?) ?? 'Línea $ref',
      origen: (v['from'] as String?) ?? '',
      destinoJson: (v['to'] as String?) ?? '',
      paradas: ids,
      incompleta: (v['incompleta'] as bool?) ?? false,
      horarios: v['horarios'],
    ));
  }
}
}
