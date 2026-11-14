// P7: el aviso de bajada pide la vibración (patrón explícito) justo cuando
// aparece, y siempre va acompañado de la caja de aviso y del anuncio a
// TalkBack. El vibrador real se sustituye por uno que anota las llamadas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutafacil/alertas.dart';
import 'package:rutafacil/data/datos_mock.dart';
import 'package:rutafacil/data/planificador.dart';
import 'package:rutafacil/ui/pantallas/p7_seguimiento.dart';
import 'package:rutafacil/ui/tema.dart';

void main() {
  late List<List<int>> vibraciones;
  late List<String> anuncios;
  late Vibrador original;

  setUp(() {
    vibraciones = [];
    anuncios = [];
    original = alertas.vibrador;
    alertas.vibrador = (patron) async => vibraciones.add(patron);
  });
  tearDown(() => alertas.vibrador = original);

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (mensaje) async {
        final datos = (mensaje as Map)['data'] as Map?;
        if (datos?['message'] is String) anuncios.add(datos!['message']);
        return null;
      },
    );
    final l1 = kLineas.first;
    final t = buscarTrayectos(l1.paradas.first, l1.paradas.last).first;
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(altoContraste: false),
        home: PantallaSeguimiento(trayecto: t),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.scrollUntilVisible(
      find.text(texto),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  bool hayAviso() =>
      find.textContaining('AVISO', skipOffstage: false).evaluate().isNotEmpty;

  testWidgets('vibra con el patrón explícito justo al aparecer el aviso', (
    tester,
  ) async {
    await montar(tester);
    await tocar(tester, 'Paso siguiente'); // subir al autobús (5 paradas)

    // Antes del aviso: avanzar paradas no vibra.
    while (true) {
      await tocar(tester, 'He pasado una parada');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      if (hayAviso()) break;
      expect(vibraciones, isEmpty, reason: 'no debe vibrar antes del aviso');
    }

    // Al aparecer el aviso: una vibración con el patrón, la caja visual y el
    // anuncio para TalkBack.
    expect(vibraciones, [kPatronAviso]);
    expect(find.text('AVISO · Prepárate'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(anuncios.last, startsWith('Aviso. Prepárate: te bajas en'));
  });

  testWidgets('vuelve a vibrar en cada parada del aviso y al llegar', (
    tester,
  ) async {
    await montar(tester);
    await tocar(tester, 'Paso siguiente');
    // Antelación por defecto: 2 paradas. Faltan 5 → 4 → 3 → 2 (aviso) → 1
    // (aviso) → llegada.
    for (var i = 0; i < 5; i++) {
      await tocar(tester, 'He pasado una parada');
    }
    expect(vibraciones.length, 3);
    expect(vibraciones, everyElement(kPatronAviso));
    expect(find.textContaining('Has llegado', skipOffstage: false), findsOne);
    expect(anuncios.last, contains('Has llegado a tu parada'));
  });

  testWidgets('si el vibrador falla, el aviso visual y hablado siguen', (
    tester,
  ) async {
    alertas.vibrador = (_) async => throw PlatformException(code: 'sin');
    await montar(tester);
    await tocar(tester, 'Paso siguiente');
    for (var i = 0; i < 3; i++) {
      await tocar(tester, 'He pasado una parada');
    }
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(hayAviso(), isTrue);
    expect(anuncios.last, startsWith('Aviso. Prepárate'));
  });
}
