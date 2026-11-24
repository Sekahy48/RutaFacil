// P3 · Detalle de línea: paradas en orden con próximos pasos.

import 'package:flutter/material.dart';

import '../../data/paradas_lineas.dart';
import '../comunes.dart';
import '../tema.dart';
import 'p5_detalle_parada.dart';

class PantallaDetalleLinea extends StatelessWidget {
  const PantallaDetalleLinea({
    super.key,
    required this.linea,
    this.volverA = 'Líneas',
  });

  final Linea linea;

  /// Texto del botón de volver (pantalla de la que venimos).
  final String volverA;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final ahora = minutoReferencia();
    final n = linea.paradas.length;

    return Pantalla(
      titulo: linea.nombre,
      volverA: volverA,
      cuerpo: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EtiquetaLinea(linea.id),
                const SizedBox(width: 2 * kEspacio),
                Expanded(
                  child: Text(
                    '${linea.resumen}\nPrimera salida '
                    '${hhmm(linea.primeraSalida)}'
                    ' · cada ${linea.frecuencia} min',
                    style: tt.bodyLarge?.copyWith(
                      color: context.paleta.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const AvisoHorariosTeoricos(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TituloSeccion('Paradas ($n)'),
          ),
          for (var i = 0; i < n; i++)
            Builder(
              builder: (context) {
                final p = paradaPorId(linea.paradas[i]);
                final horas = linea
                    .pasosPor(i, desde: ahora)
                    .map(hhmm)
                    .toList();
                return FilaNavegable(
                  titulo: '${i + 1}. ${p.nombre}',
                  subtitulo: textoProximos(horas),
                  etiqueta:
                      'Parada ${i + 1} de $n: ${p.nombre}. '
                      '${textoProximosHablado(horas)}. Abrir detalle de parada.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PantallaDetalleParada(
                        parada: p,
                        volverA: linea.nombre,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
