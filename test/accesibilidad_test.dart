// Pruebas automáticas de accesibilidad (semana 4).
//
// Para cada una de las 8 pantallas (más los estados de error de P1, aviso de
// P7 y mapa sin conexión), en tema normal y de alto contraste:
//  - androidTapTargetGuideline   (áreas táctiles ≥ 48×48 dp)
//  - labeledTapTargetGuideline   (todo lo tocable tiene nombre)
//  - textContrastGuideline       (contraste de texto WCAG AA)
// Y además: texto al 200 % sin desbordamientos en ninguna pantalla.
//
// Se cargan las fuentes Geist reales para que las medidas de texto se
// parezcan a las del móvil (con la fuente de pruebas por defecto cada letra
// ocupa 1 em y todo sale más ancho).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutafacil/data/datos_mock.dart';
import 'package:rutafacil/data/planificador.dart';
import 'package:rutafacil/estado.dart';
import 'package:rutafacil/ui/armazon.dart';
import 'package:rutafacil/ui/pantallas/p1_buscar.dart';
import 'package:rutafacil/ui/pantallas/p2_lineas.dart';
import 'package:rutafacil/ui/pantallas/p3_detalle_linea.dart';
import 'package:rutafacil/ui/pantallas/p4_paradas.dart';
import 'package:rutafacil/ui/pantallas/p5_detalle_parada.dart';
import 'package:rutafacil/ui/pantallas/p6_mapa.dart';
import 'package:rutafacil/ui/pantallas/p7_seguimiento.dart';
import 'package:rutafacil/ui/pantallas/p8_ajustes.dart';
import 'package:rutafacil/ui/tema.dart';

Future<void> _cargarFuentes() async {
  Future<void> cargar(String familia, List<String> archivos) async {
    final loader = FontLoader(familia);
    for (final a in archivos) {
      final bytes = File('assets/fonts/$a').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await cargar('Geist', [
    'Geist-Regular.ttf',
    'Geist-Medium.ttf',
    'Geist-SemiBold.ttf',
    'Geist-Bold.ttf',
  ]);
  await cargar('GeistSerif', ['GeistSerif-Regular.ttf']);
}

/// Pantalla a probar: cómo construirla y cómo llevarla al estado deseado.
class _Caso {
  const _Caso(this.nombre, this.construir, {this.preparar});
  final String nombre;
  final Widget Function() construir;
  final Future<void> Function(WidgetTester tester)? preparar;
}

/// Trayecto directo de la línea 1 de cabecera a final (tiene aviso).
Trayecto _trayectoL1() {
  final l1 = kLineas.first;
  return buscarTrayectos(l1.paradas.first, l1.paradas.last).first;
}

Finder get _lista => find.byType(Scrollable).first;

/// Desplaza la lista hasta [texto] (aunque aún no esté construido) y lo toca.
Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.scrollUntilVisible(find.text(texto), 200, scrollable: _lista);
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

Future<void> _irArriba(WidgetTester tester) async {
  await tester.drag(_lista, const Offset(0, 5000));
  await tester.pumpAndSettle();
}

Future<void> _llevarAAviso(WidgetTester tester) async {
  // Paso 1 (espera) → paso 2 (viaje); luego avanzar paradas hasta el aviso,
  // que aparece arriba del todo.
  await _tocar(tester, 'Paso siguiente');
  for (var i = 0; i < 20; i++) {
    await _irArriba(tester);
    if (find.textContaining('AVISO').evaluate().isNotEmpty) break;
    await _tocar(tester, 'He pasado una parada');
  }
  expect(find.textContaining('AVISO'), findsOneWidget);
}

Future<void> _provocarErrorP1(WidgetTester tester) async {
  await _tocar(tester, 'Buscar trayecto');
  expect(find.textContaining('Error:'), findsWidgets);
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
  await tester.pumpAndSettle();
}

Future<void> _resultadosP1(WidgetTester tester) async {
  final l1 = kLineas.first;
  final campos = find.byType(EditableText);
  await tester.enterText(campos.at(0), paradaPorId(l1.paradas.first).nombre);
  await tester.enterText(campos.at(1), paradaPorId(l1.paradas.last).nombre);
  await _tocar(tester, 'Buscar trayecto');
  expect(find.textContaining('encontrado'), findsOneWidget);
}

final _casos = <_Caso>[
  _Caso('P1 buscar', () => const PantallaBuscar()),
  _Caso('P1 error', () => const PantallaBuscar(), preparar: _provocarErrorP1),
  _Caso('P1 resultados', () => const PantallaBuscar(), preparar: _resultadosP1),
  _Caso('P2 líneas', () => const PantallaLineas()),
  _Caso('P3 detalle línea', () => PantallaDetalleLinea(linea: kLineas.first)),
  _Caso('P4 paradas', () => const PantallaParadas()),
  _Caso(
    'P5 detalle parada',
    () => PantallaDetalleParada(parada: kParadas.first, volverA: 'Paradas'),
  ),
  // Hospital: todas sus tarjetas de línea son «final de línea».
  _Caso(
    'P5 final de línea',
    () => PantallaDetalleParada(
      parada: paradaPorId('hospital'),
      volverA: 'Paradas',
    ),
  ),
  _Caso(
    'P6 mapa',
    () => const PantallaMapa(),
    preparar: (_) async => PantallaMapa.conexionParaPruebas = true,
  ),
  _Caso(
    'P6 sin conexión',
    () => const PantallaMapa(),
    preparar: (_) async => PantallaMapa.conexionParaPruebas = false,
  ),
  _Caso('P7 seguimiento', () => PantallaSeguimiento(trayecto: _trayectoL1())),
  _Caso(
    'P7 aviso',
    () => PantallaSeguimiento(trayecto: _trayectoL1()),
    preparar: _llevarAAviso,
  ),
  _Caso('P8 ajustes', () => const PantallaAjustes()),
  _Caso('Barra inferior (armazón)', () => const Armazon()),
];

Future<void> _montar(
  WidgetTester tester,
  _Caso caso, {
  required bool altoContraste,
  double escalaTexto = 1.0,
}) async {
  tester.view.physicalSize = const Size(1080, 2400); // Pixel 8 aprox.
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  // Los casos de P6 fijan la conexión antes de construir la pantalla.
  if (caso.nombre.startsWith('P6')) await caso.preparar!(tester);

  await tester.pumpWidget(
    MaterialApp(
      theme: construirTema(altoContraste: altoContraste),
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
      home: caso.construir(),
    ),
  );
  await tester.pumpAndSettle();
  if (!caso.nombre.startsWith('P6') && caso.preparar != null) {
    await caso.preparar!(tester);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _cargarFuentes();
    // flutter_map guarda en caché las teselas con path_provider, que no
    // existe en las pruebas: se le da una carpeta temporal.
    final tmp = Directory.systemTemp.createTempSync('rutafacil_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tmp.path,
        );
  });
  tearDown(() {
    PantallaMapa.conexionParaPruebas = null;
    estado.pestana.value = Pestana.buscar;
    estado.antelacion.value = 2;
  });

  for (final alto in [false, true]) {
    final tema = alto ? 'alto contraste' : 'tema normal';
    group('Guías de accesibilidad · $tema', () {
      for (final caso in _casos) {
        testWidgets(caso.nombre, (tester) async {
          final semantica = tester.ensureSemantics();
          await _montar(tester, caso, altoContraste: alto);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantica.dispose();
        });
      }
    });
  }

  group('Texto al 200 % sin desbordamientos', () {
    for (final alto in [false, true]) {
      for (final caso in _casos) {
        final tema = alto ? 'alto contraste' : 'normal';
        testWidgets('${caso.nombre} · $tema', (tester) async {
          await _montar(tester, caso, altoContraste: alto, escalaTexto: 2.0);
          // Un overflow de RenderFlex se notifica como excepción.
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  // Pines (etiquetas de parada) del mapa: colores y grosor de la paleta de
  // cada tema; en alto contraste, tokens AC (fondo AC, texto AC, borde de
  // acento de 3 dp). Con texto al 200 % el nombre cabe entero.
  group('Pines del mapa', () {
    final mapa = _casos.firstWhere((c) => c.nombre == 'P6 mapa');

    for (final alto in [false, true]) {
      final tema = alto ? 'alto contraste' : 'tema normal';
      final fondo = alto ? kAltoPinFondo : kNormalPinFondo;
      final texto = alto ? kAltoPinTexto : kNormalPinTexto;
      final borde = alto ? kAltoPinBorde : kNormalPinBorde;
      final grosor = alto ? kAltoPinGrosor : kNormalPinGrosor;

      testWidgets('usan los colores de la paleta · $tema', (tester) async {
        await _montar(tester, mapa, altoContraste: alto);
        for (final parada in kParadas) {
          final nombre = find.text(parada.nombre);
          expect(nombre, findsOneWidget);
          expect(tester.widget<Text>(nombre).style?.color, texto);
          final material = tester.widget<Material>(
            find.ancestor(of: nombre, matching: find.byType(Material)).first,
          );
          expect(material.color, fondo);
          final forma = material.shape! as RoundedRectangleBorder;
          expect(forma.side.color, borde);
          expect(forma.side.width, grosor);
          expect(forma.borderRadius, kRadioBorde);
        }
      });

      for (final escala in [1.0, 2.0]) {
        testWidgets('el nombre cabe entero y el pin mide ≥ 48 dp · $tema · '
            'texto ${(escala * 100).round()} %', (tester) async {
          await _montar(tester, mapa, altoContraste: alto, escalaTexto: escala);
          expect(tester.takeException(), isNull);
          for (final parada in kParadas) {
            final nombre = find.text(parada.nombre);
            final parrafo = tester.renderObject<RenderParagraph>(nombre);
            expect(
              parrafo.didExceedMaxLines,
              isFalse,
              reason: '${parada.nombre} se recorta',
            );
            final caja = tester.getSize(
              find.ancestor(of: nombre, matching: find.byType(Material)).first,
            );
            expect(caja.width, greaterThanOrEqualTo(kTactilMinimo));
            expect(caja.height, greaterThanOrEqualTo(kTactilMinimo));
            expect(
              parrafo.size.width,
              lessThanOrEqualTo(caja.width - 2 * grosor),
            );
          }
        });
      }
    }
  });
}
