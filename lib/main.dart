// RutaFácil — prototipo accesible de autobús urbano (iteración 1).
// Datos de ejemplo inventados, sin tiempo real, horarios teóricos.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/paradas_lineas.dart';
import 'estado.dart';
import 'ui/armazon.dart';
import 'ui/tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await cargarDatos();
  runApp(const RutaFacilApp());
}

class RutaFacilApp extends StatelessWidget {
  const RutaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: estado.altoContraste,
      builder: (context, alto, _) => MaterialApp(
        title: 'RutaFácil',
        debugShowCheckedModeBanner: false,
        theme: construirTema(altoContraste: alto),
        // Textos internos de Material (tooltips, TalkBack) en español.
        locale: const Locale('es', 'ES'),
        supportedLocales: const [Locale('es', 'ES')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Armazon(),
      ),
    );
  }
}
