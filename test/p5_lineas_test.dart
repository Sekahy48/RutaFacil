// RC-01: en P5 las tarjetas de «Líneas que pasan» son botones que abren P3,
// y el botón de volver de P3 lleva el nombre de la parada.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutafacil/data/datos_mock.dart';
import 'package:rutafacil/estado.dart';
import 'package:rutafacil/ui/armazon.dart';
import 'package:rutafacil/ui/comunes.dart';
import 'package:rutafacil/ui/pantallas/p3_detalle_linea.dart';
import 'package:rutafacil/ui/pantallas/p5_detalle_parada.dart';
import 'package:rutafacil/ui/tema.dart';

Future<void> _montarP5(WidgetTester tester, String idParada) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: construirTema(altoContraste: false),
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: PantallaDetalleParada(
        parada: paradaPorId(idParada),
        volverA: 'Paradas',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Etiqueta que debe leer TalkBack para la tarjeta de [l] en [idParada].
String _etiquetaEsperada(Linea l, String idParada) {
  final i = l.paradas.indexOf(idParada);
  final horas = l.pasosPor(i, desde: minutoReferencia()).map(hhmm).toList();
  if (i == l.paradas.length - 1) {
    final llegadas = horas.isEmpty
        ? 'Sin más llegadas hoy'
        : 'Llegadas: ${horas.join(', ')}';
    return '${l.nombre}, final de línea. $llegadas. '
        'Abrir detalle de la línea.';
  }
  return '${l.nombre}, a ${l.destino}. ${textoProximosHablado(horas)}. '
      'Abrir detalle de la línea.';
}

Future<void> _tocarTexto(WidgetTester tester, String texto) async {
  await tester.scrollUntilVisible(
    find.text(texto),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

/// Comprueba que está abierta P3 de [linea] con «‹ [volverA]».
void _esperarP3(String linea, String volverA) {
  expect(find.byType(PantallaDetalleLinea), findsOneWidget);
  final p3 = find.byType(PantallaDetalleLinea);
  expect(find.descendant(of: p3, matching: find.text(linea)), findsOneWidget);
  expect(
    find.descendant(of: p3, matching: find.text('‹ $volverA')),
    findsOneWidget,
  );
  expect(find.bySemanticsLabel('Volver a $volverA'), findsOneWidget);
}

void main() {
  tearDown(() => estado.pestana.value = Pestana.buscar);

  group('P5 · tarjetas de línea', () {
    testWidgets('en la app, el «atrás» del sistema desde P3 vuelve a P5', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(altoContraste: false),
          locale: const Locale('es', 'ES'),
          supportedLocales: const [Locale('es', 'ES')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Armazon(),
        ),
      );
      estado.irA(Pestana.paradas);
      await tester.pumpAndSettle();
      await _tocarTexto(tester, 'Catedral');
      await _tocarTexto(tester, 'Línea 1 · a Hospital');
      _esperarP3('Línea 1', 'Catedral');

      // Botón «atrás» de Android.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PantallaDetalleLinea), findsNothing);
      expect(find.text('Líneas que pasan').hitTestable(), findsOneWidget);
      expect(estado.pestana.value, Pestana.paradas);
      // Y desde P5, a la lista de paradas (no a Líneas).
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PantallaDetalleParada), findsNothing);
      expect(estado.pestana.value, Pestana.paradas);
    });

    testWidgets('tocar la tarjeta abre P3 de esa línea con «‹ Catedral»', (
      tester,
    ) async {
      await _montarP5(tester, 'catedral');
      await _tocarTexto(tester, 'Línea 3 · a Universidad');
      _esperarP3('Línea 3', 'Catedral');
      // Las tarjetas de P5 ya no están (P3 la tapa por completo).
      expect(
        find.byType(PantallaDetalleParada, skipOffstage: true),
        findsNothing,
      );
    });

    testWidgets('volver desde P3 regresa a P5', (tester) async {
      await _montarP5(tester, 'catedral');
      await _tocarTexto(tester, 'Línea 1 · a Hospital');
      _esperarP3('Línea 1', 'Catedral');
      await tester.tap(find.text('‹ Catedral'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaDetalleLinea), findsNothing);
      expect(find.text('Líneas que pasan'), findsOneWidget);
      expect(find.text('‹ Paradas'), findsOneWidget);
    });

    testWidgets('la acción semántica de la tarjeta también abre P3', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _montarP5(tester, 'catedral');
      final l1 = kLineas.firstWhere((l) => l.id == 'L1');
      tester.semantics.tap(
        find.semantics.byLabel(_etiquetaEsperada(l1, 'catedral')),
      );
      await tester.pumpAndSettle();
      _esperarP3('Línea 1', 'Catedral');
      semantica.dispose();
    });

    testWidgets('se puede encadenar P5 → P3 → P5 → P3 y volver paso a paso', (
      tester,
    ) async {
      await _montarP5(tester, 'catedral');
      await _tocarTexto(tester, 'Línea 1 · a Hospital');
      _esperarP3('Línea 1', 'Catedral');
      await _tocarTexto(tester, '6. Hospital');
      expect(find.text('‹ Línea 1'), findsOneWidget);
      await _tocarTexto(tester, 'Línea 2 · final de línea');
      _esperarP3('Línea 2', 'Hospital');
      await _tocarTexto(tester, '1. Estación');
      await _tocarTexto(tester, 'Línea 3 · a Universidad');
      _esperarP3('Línea 3', 'Estación');
      expect(tester.takeException(), isNull);

      // Atrás deshace la cadena en orden.
      for (final esperado in [
        '‹ Línea 2', // P5 Estación
        '‹ Hospital', // P3 Línea 2
        '‹ Línea 1', // P5 Hospital
        '‹ Catedral', // P3 Línea 1
        '‹ Paradas', // P5 Catedral
      ]) {
        final volver = find.textContaining('‹ ').hitTestable();
        await tester.tap(volver.first);
        await tester.pumpAndSettle();
        expect(find.text(esperado).hitTestable(), findsOneWidget);
      }
    });
  });

  group('P5 · semántica de las tarjetas', () {
    for (final idParada in ['catedral', 'hospital', 'universidad']) {
      testWidgets('cada tarjeta es un solo botón con su frase · $idParada', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        await _montarP5(tester, idParada);
        for (final l in lineasDeParada(idParada)) {
          final etiqueta = _etiquetaEsperada(l, idParada);
          expect(etiqueta.contains('·'), isFalse);
          final nodo = find.semantics.byLabel(etiqueta);
          expect(nodo, findsOne, reason: etiqueta);
          expect(
            tester.getSemantics(find.text(_tituloVisible(l, idParada))),
            isSemantics(label: etiqueta, isButton: true, hasTapAction: true),
          );
          // Ningún otro nodo repite el texto de la tarjeta.
          expect(
            find.semantics.byLabel(RegExp(RegExp.escape(l.nombre))),
            findsOne,
            reason: 'nodo repetido para ${l.nombre}',
          );
        }
        // Ni el título ni los horarios visibles (con «·») salen sueltos.
        expect(find.semantics.byLabel(RegExp('·')), findsNothing);
        semantica.dispose();
      });
    }
  });
}

String _tituloVisible(Linea l, String idParada) => l.paradas.last == idParada
    ? '${l.nombre} · final de línea'
    : '${l.nombre} · a ${l.destino}';
