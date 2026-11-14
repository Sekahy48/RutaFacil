// Armazón con la barra de navegación inferior:
// Buscar · Líneas · Paradas · Mapa · Ajustes.
// Cada pestaña tiene su propio Navigator para que los detalles (P3, P5)
// se abran sin perder la barra. El seguimiento (P7) se abre por encima,
// en el Navigator raíz, y por eso no muestra la barra.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../estado.dart';
import 'pantallas/p1_buscar.dart';
import 'pantallas/p2_lineas.dart';
import 'pantallas/p4_paradas.dart';
import 'pantallas/p6_mapa.dart';
import 'pantallas/p8_ajustes.dart';
import 'comunes.dart';
import 'tema.dart';

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

/// Barra inferior propia (no NavigationBar): crece con el texto sin límite.
/// Si las cinco etiquetas no caben en una fila, se reparten en dos filas
/// (3 + 2) o más, de modo que ninguna palabra se corte ni se recorte.
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

  /// Número de columnas tal que la etiqueta más ancha quepa entera.
  int _columnas(BuildContext context, double ancho) {
    final escalador = MediaQuery.textScalerOf(context);
    var maximo = 0.0;
    for (final (_, texto, _) in _destinos) {
      final tp = TextPainter(
        text: TextSpan(
          text: texto,
          style: kEstiloEtiqueta.copyWith(fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
        textScaler: escalador,
        maxLines: 1,
      )..layout();
      if (tp.width > maximo) maximo = tp.width;
      tp.dispose();
    }
    // 8 dp de margen a cada lado del texto + 4 dp de separación.
    final necesario = maximo + 2 * kEspacio + 4;
    for (var n = _destinos.length; n > 1; n--) {
      if (ancho / n >= necesario) return n;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Material(
      color: p.pestanaInactiva,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: p.borde, width: kBorde),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, restr) {
                final n = _columnas(context, restr.maxWidth);
                final ancho = (restr.maxWidth / n).floorToDouble();
                return Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: Wrap(
                    children: [
                      for (var i = 0; i < _destinos.length; i++)
                        SizedBox(
                          width: ancho,
                          child: _Pestana(
                            icono: _destinos[i].$1,
                            texto: _destinos[i].$2,
                            etiqueta: _destinos[i].$3,
                            indice: i,
                            total: _destinos.length,
                            activa: i == seleccionada,
                            onTap: () => onSeleccion(i),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Pestaña: activa = relleno de acento + negrita; inactiva = sin relleno.
class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.icono,
    required this.texto,
    required this.etiqueta,
    required this.indice,
    required this.total,
    required this.activa,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final String etiqueta;
  final int indice;
  final int total;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final color = activa ? p.sobreAcento : p.textoSecundario;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        container: true,
        button: true,
        selected: activa,
        label: 'Pestaña $etiqueta, ${indice + 1} de $total',
        onTap: onTap,
        excludeSemantics: true,
        child: Tooltip(
          message: etiqueta,
          excludeFromSemantics: true,
          child: Material(
            color: activa ? p.acento : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: kRadioBorde,
              side: activa
                  ? BorderSide(color: p.acento, width: kBorde)
                  : BorderSide.none,
            ),
            child: Tocable(
              onTap: onTap,
              anilloDentro: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: kEspacio,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icono, color: color),
                      const SizedBox(height: 4),
                      Text(
                        texto,
                        textAlign: TextAlign.center,
                        style: kEstiloEtiqueta.copyWith(
                          color: color,
                          fontWeight: activa
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
