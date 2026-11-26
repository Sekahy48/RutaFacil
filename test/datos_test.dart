// Datos de ejemplo y planificador: integridad de las paradas y líneas,
// cobertura de trayectos entre pares de paradas y variedad de casos.

import 'package:flutter_test/flutter_test.dart';
import 'package:rutafacil/data/datos_mock.dart';
import 'package:rutafacil/data/planificador.dart';

/// Porcentaje mínimo de pares origen→destino (distintos) con trayecto
/// directo o con 1 trasbordo a la hora de referencia. Con los datos actuales
/// es 100/110 (90,9 %): solo faltan los que salen de Hospital, que es solo
/// final de línea (lo usa el caso «P5 final de línea»).
const double kCoberturaMinima = 0.90;

/// Todos los pares ordenados de paradas distintas.
Iterable<(Parada, Parada)> _pares() sync* {
  for (final o in kParadas) {
    for (final d in kParadas) {
      if (o.id != d.id) yield (o, d);
    }
  }
}

List<Trayecto> _buscar(Parada o, Parada d) =>
    buscarTrayectos(o.id, d.id, desde: kHoraReferenciaFija);

void main() {
  test('la hora fija sigue activada', () {
    expect(kUsarHoraFija, isTrue);
  });

  group('Integridad de los datos', () {
    test('ids y nombres de parada únicos (también sin tildes)', () {
      final ids = kParadas.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids repetidos: $ids');
      final nombres = kParadas.map((p) => normalizar(p.nombre)).toList();
      expect(
        nombres.toSet().length,
        nombres.length,
        reason: 'nombres repetidos: $nombres',
      );
      for (final p in kParadas) {
        expect(p.id, isNotEmpty);
        expect(p.nombre.trim(), isNotEmpty);
        expect(paradaPorNombre(p.nombre)?.id, p.id);
      }
    });

    test('ids, nombres y resúmenes de línea únicos y coherentes', () {
      final ids = kLineas.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids repetidos: $ids');
      final resumenes = kLineas.map((l) => l.resumen).toList();
      expect(resumenes.toSet().length, resumenes.length);
      for (final l in kLineas) {
        // «Líneas 1 y 5» sale del id: tiene que ser «L» + el número del nombre.
        expect(l.id, matches(RegExp(r'^L[1-9][0-9]*$')));
        expect(l.nombre, 'Línea ${l.id.substring(1)}');
        expect(l.resumen.trim(), isNotEmpty);
      }
      // Ningún nombre es prefijo de otro («Línea 1» / «Línea 10»): TalkBack
      // y las búsquedas por texto los confundirían.
      for (final a in kLineas) {
        for (final b in kLineas) {
          if (a.id == b.id) continue;
          expect(
            b.nombre.startsWith(a.nombre),
            isFalse,
            reason: '«${a.nombre}» es prefijo de «${b.nombre}»',
          );
        }
      }
    });

    test('cada línea: ≥ 2 paradas existentes, sin repetir, con horarios '
        'coherentes', () {
      final ids = kParadas.map((p) => p.id).toSet();
      for (final l in kLineas) {
        final r = l.id;
        expect(l.paradas.length, greaterThanOrEqualTo(2), reason: r);
        expect(l.paradas.toSet().length, l.paradas.length, reason: r);
        for (final id in l.paradas) {
          expect(ids, contains(id), reason: '$r usa la parada $id');
        }
        expect(l.offsets.length, l.paradas.length, reason: r);
        expect(l.offsets.first, 0, reason: r);
        for (var i = 1; i < l.offsets.length; i++) {
          expect(l.offsets[i], greaterThan(l.offsets[i - 1]), reason: r);
        }
        expect(l.frecuencia, greaterThan(0), reason: r);
        expect(l.primeraSalida, lessThanOrEqualTo(kFinServicio), reason: r);
        // A la hora de referencia hay servicio en todas las paradas.
        for (var i = 0; i < l.paradas.length; i++) {
          expect(
            l.pasosPor(i, desde: kHoraReferenciaFija),
            isNotEmpty,
            reason: '$r sin pasos por ${l.paradas[i]}',
          );
        }
      }
    });

    test('ninguna parada sin línea ni línea sin paradas', () {
      for (final p in kParadas) {
        expect(lineasDeParada(p.id), isNotEmpty, reason: '${p.id} huérfana');
      }
      for (final l in kLineas) {
        expect(l.paradas, isNotEmpty, reason: l.id);
      }
    });
  });

  group('Cobertura de trayectos', () {
    test('≥ ${(kCoberturaMinima * 100).round()} % de los pares tienen '
        'trayecto con 1 trasbordo como máximo', () {
      var con = 0, total = 0;
      final sin = <String>[];
      for (final (o, d) in _pares()) {
        total++;
        final t = _buscar(o, d);
        if (t.isNotEmpty) {
          con++;
        } else {
          sin.add('${o.id}→${d.id}');
        }
        for (final x in t) {
          expect(x.tramos.length, lessThanOrEqualTo(2));
          expect(x.origen.id, o.id);
          expect(x.destino.id, d.id);
        }
      }
      expect(
        con / total,
        greaterThanOrEqualTo(kCoberturaMinima),
        reason: '$con/$total con trayecto. Sin trayecto: $sin',
      );
    });

    test('los únicos pares sin trayecto salen de una parada que solo es '
        'final de línea', () {
      for (final (o, d) in _pares()) {
        if (_buscar(o, d).isNotEmpty) continue;
        final soloFinal = lineasDeParada(o.id)
            .every((l) => l.paradas.last == o.id);
        expect(soloFinal, isTrue, reason: '${o.id}→${d.id} sin trayecto');
      }
    });

    test('los trasbordos son siempre entre líneas distintas y en una parada '
        'de las dos', () {
      for (final (o, d) in _pares()) {
        for (final t in _buscar(o, d).where((t) => t.conTrasbordo)) {
          final (a, b) = (t.tramos[0], t.tramos[1]);
          expect(a.linea.id, isNot(b.linea.id));
          expect(a.linea.nombre, isNot(b.linea.nombre));
          expect(a.paradaBajada.id, b.paradaSubida.id);
          expect(b.salida, greaterThanOrEqualTo(a.llegada));
        }
      }
    });

    test('hay casos variados: directos, solo con trasbordo y con varias '
        'alternativas', () {
      var directos = 0, soloTrasbordo = 0, varias = 0;
      for (final (o, d) in _pares()) {
        final t = _buscar(o, d);
        if (t.isEmpty) continue;
        if (t.any((x) => !x.conTrasbordo)) {
          directos++;
        } else {
          soloTrasbordo++;
        }
        if (t.length > 1) varias++;
      }
      expect(directos, greaterThanOrEqualTo(30));
      expect(soloTrasbordo, greaterThanOrEqualTo(20));
      expect(varias, greaterThanOrEqualTo(30));
    });

    test('la línea del 2.º tramo puede pasar por el origen después del '
        'destino (Quevedo → Lastra)', () {
      // L9 pasa por Quevedo, pero al final (después de Lastra): no sirve
      // como directo, sí como segundo tramo desde Estación.
      final l9 = kLineas.firstWhere((l) => l.id == 'L9');
      expect(
        l9.paradas.indexOf('quevedo'),
        greaterThan(l9.paradas.indexOf('lastra')),
      );
      final t = buscarTrayectos(
        'quevedo',
        'lastra',
        desde: kHoraReferenciaFija,
      );
      expect(t, isNotEmpty);
      expect(t.first.nombreLineas, 'Líneas 6 y 9');
      expect(t.first.textoTrasbordo, '1 trasbordo en Estación');
    });
  });

  // Datos de los que dependen otras pruebas (P5, P7): si cambian, esas
  // pruebas dejan de comprobar lo que dicen.
  group('Supuestos de otras pruebas', () {
    test('Estación → Hospital: el más rápido sigue siendo la Línea 1 '
        'directa (P7)', () {
      final t = buscarTrayectos(
        'estacion',
        'hospital',
        desde: kHoraReferenciaFija,
      );
      expect(t.first.nombreLineas, 'Línea 1');
      expect(t.first.conTrasbordo, isFalse);
      // Sin empate: el orden no depende de la estabilidad de sort.
      expect(t[1].duracion, greaterThan(t.first.duracion));
    });

    test('Hospital solo es final de línea (P5 final de línea)', () {
      for (final l in lineasDeParada('hospital')) {
        expect(l.paradas.last, 'hospital', reason: l.id);
      }
    });
  });
}
