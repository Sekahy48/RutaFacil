// Armazón con la barra de navegación inferior:
// Buscar · Líneas · Paradas · Mapa · Ajustes.
// Cada pestaña tiene su propio Navigator para que los detalles (P3, P5)
// se abran sin perder la barra. El seguimiento (P7) se abre por encima,
// en el Navigator raíz, y por eso no muestra la barra.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../estado.dart';
import 'pantallas/p1_buscar.dart';
import 'pantallas/p2_lineas.dart';
import 'pantallas/p4_paradas.dart';
import 'pantallas/p6_mapa.dart';
import 'pantallas/p8_ajustes.dart';

class Armazon extends StatefulWidget {
  const Armazon({super.key});

  @override
  State<Armazon> createState() => _ArmazonState();
}

class _ArmazonState extends State<Armazon> {
  final _navegadores = {
    for (final p in Pestana.values) p: GlobalKey<NavigatorState>(),
  };

  Widget _raiz(Pestana p) => switch (p) {
    Pestana.buscar => const PantallaBuscar(),
    Pestana.lineas => const PantallaLineas(),
    Pestana.paradas => const PantallaParadas(),
    Pestana.mapa => const PantallaMapa(),
    Pestana.ajustes => const PantallaAjustes(),
  };

  void _seleccionar(int i) {
    final p = Pestana.values[i];
    if (p == estado.pestana.value) {
      // Segundo toque en la pestaña activa: volver a su pantalla inicial.
      _navegadores[p]!.currentState?.popUntil((r) => r.isFirst);
    }
    estado.irA(p);
  }

  void _atras() {
    final actual = estado.pestana.value;
    final nav = _navegadores[actual]!.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (actual != Pestana.buscar) {
      estado.irA(Pestana.buscar);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Pestana>(
      valueListenable: estado.pestana,
      builder: (context, pestana, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _atras();
          },
          child: Scaffold(
            body: IndexedStack(
              index: pestana.index,
              children: [
                for (final p in Pestana.values)
                  Navigator(
                    key: _navegadores[p],
                    onGenerateRoute: (_) =>
                        MaterialPageRoute(builder: (_) => _raiz(p)),
                  ),
              ],
            ),
            bottomNavigationBar: _BarraInferior(
              seleccionada: pestana.index,
              onSeleccion: _seleccionar,
            ),
          ),
        );
      },
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.seleccionada, required this.onSeleccion});

  final int seleccionada;
  final ValueChanged<int> onSeleccion;

  static const _destinos = [
    (Icons.search, 'Buscar', 'Buscar ruta'),
    (Icons.directions_bus_outlined, 'Líneas', 'Líneas'),
    (Icons.place_outlined, 'Paradas', 'Paradas'),
    (Icons.map_outlined, 'Mapa', 'Mapa'),
    (Icons.settings_outlined, 'Ajustes', 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Cinco pestañas en una fila no caben con texto al 200 %. Se limita la
    // escala de esta barra a 1,3× para que no se recorte; el resto de la app
    // sí escala hasta 200 %. TalkBack lee la etiqueta completa.
    final escala = math.min(mq.textScaler.scale(14) / 14, 1.3);
    final esquema = Theme.of(context).colorScheme;
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(escala)),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: esquema.outline, width: 1.5)),
        ),
        child: NavigationBar(
          selectedIndex: seleccionada,
          onDestinationSelected: onSeleccion,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64 + 20 * escala,
          destinations: [
            for (final (icono, texto, tooltip) in _destinos)
              NavigationDestination(
                icon: Icon(icono),
                selectedIcon: Icon(icono, weight: 700),
                label: texto,
                tooltip: tooltip,
              ),
          ],
        ),
      ),
    );
  }
}
