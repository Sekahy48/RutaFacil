// Cálculo de trayectos con los datos de ejemplo:
// directos o con 1 trasbordo, hasta 3 opciones, ordenadas por duración.

import 'datos_mock.dart';

/// Un tramo en una sola línea: subir en [desde] y bajar en [hasta]
/// (índices dentro de `linea.paradas`).
class Tramo {
  const Tramo({
    required this.linea,
    required this.desde,
    required this.hasta,
    required this.salida,
  });

  final Linea linea;
  final int desde;
  final int hasta;

  /// Hora (min) a la que el autobús sale de la parada de subida.
  final int salida;

  int get llegada => salida + linea.offsets[hasta] - linea.offsets[desde];

  Parada get paradaSubida => paradaPorId(linea.paradas[desde]);
  Parada get paradaBajada => paradaPorId(linea.paradas[hasta]);

  /// Paradas recorridas en este tramo, incluida la de subida y la de bajada.
  List<Parada> get paradas => [
    for (var i = desde; i <= hasta; i++) paradaPorId(linea.paradas[i]),
  ];
}

class Trayecto {
  const Trayecto(this.tramos);

  final List<Tramo> tramos;

  int get salida => tramos.first.salida;
  int get llegada => tramos.last.llegada;

  /// Desde que sale el primer autobús hasta llegar (incluye espera
  /// del trasbordo, no la espera inicial).
  int get duracion => llegada - salida;

  bool get conTrasbordo => tramos.length > 1;

  Parada get origen => tramos.first.paradaSubida;
  Parada get destino => tramos.last.paradaBajada;

  String get nombreLineas => tramos.length == 1
      ? tramos.first.linea.nombre
      : 'Líneas ${tramos.map((t) => t.linea.id.substring(1)).join(' y ')}';

  String get textoTrasbordo => conTrasbordo
      ? '1 trasbordo en ${tramos.first.paradaBajada.nombre}'
      : 'sin trasbordo';
}

/// Primera salida de [linea] desde la parada en posición [indice]
/// a partir del minuto [desde], o null si ya no hay servicio.
int? _proximaSalida(Linea linea, int indice, int desde) {
  final p = linea.pasosPor(indice, desde: desde, maximo: 1);
  return p.isEmpty ? null : p.first;
}

/// Busca hasta [maximo] trayectos de [origenId] a [destinoId].
List<Trayecto> buscarTrayectos(
  String origenId,
  String destinoId, {
  int? desde,
  int maximo = 3,
}) {
  final ahora = desde ?? minutoReferencia();
  final opciones = <Trayecto>[];

  // Directos.
  for (final l in kLineas) {
    final i = l.paradas.indexOf(origenId);
    final j = l.paradas.indexOf(destinoId);
    if (i < 0 || j <= i) continue;
    final s = _proximaSalida(l, i, ahora);
    if (s == null) continue;
    opciones.add(Trayecto([Tramo(linea: l, desde: i, hasta: j, salida: s)]));
  }

  // Con 1 trasbordo: el mejor por cada par de líneas (A, B).
  for (final a in kLineas) {
    final i = a.paradas.indexOf(origenId);
    if (i < 0) continue;
    // Si A ya llega al destino, no tiene sentido cambiar.
    if (a.paradas.indexOf(destinoId) > i) continue;
    final s1 = _proximaSalida(a, i, ahora);
    if (s1 == null) continue;

    for (final b in kLineas) {
      if (b.id == a.id) continue;
      final n = b.paradas.indexOf(destinoId);
      if (n < 0) continue;
      // Si B pasa por el origen antes del destino, mejor subir a B
      // directamente (ya está entre los directos). Si pasa después del
      // destino, B sí sirve para el segundo tramo.
      final o = b.paradas.indexOf(origenId);
      if (o >= 0 && o < n) continue;

      Trayecto? mejor;
      for (var k = i + 1; k < a.paradas.length; k++) {
        final m = b.paradas.indexOf(a.paradas[k]);
        if (m < 0 || m >= n) continue;
        final t1 = Tramo(linea: a, desde: i, hasta: k, salida: s1);
        final s2 = _proximaSalida(b, m, t1.llegada);
        if (s2 == null) continue;
        final t = Trayecto([
          t1,
          Tramo(linea: b, desde: m, hasta: n, salida: s2),
        ]);
        if (mejor == null || t.llegada < mejor.llegada) mejor = t;
      }
      if (mejor != null) opciones.add(mejor);
    }
  }

  opciones.sort((x, y) {
    final c = x.duracion.compareTo(y.duracion);
    return c != 0 ? c : x.tramos.length.compareTo(y.tramos.length);
  });
  return opciones.take(maximo).toList();
}
