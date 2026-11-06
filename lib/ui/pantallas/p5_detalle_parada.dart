// P5 · Detalle de parada.

import 'package:flutter/material.dart';

import '../../data/datos_mock.dart';
import '../../estado.dart';
import '../comunes.dart';

class PantallaDetalleParada extends StatelessWidget {
  const PantallaDetalleParada({
    super.key,
    required this.parada,
    required this.volverA,
  });

  final Parada parada;

  /// Texto del botón de volver (pantalla de la que venimos).
  final String volverA;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final ahora = minutoReferencia();
    final lineas = lineasDeParada(parada.id);
    final apilar = MediaQuery.textScalerOf(context).scale(10) > 14;

    final botonOrigen = OutlinedButton(
      onPressed: () => estado.usarComoOrigen(parada.id),
      child: Semantics(
        label: 'Usar ${parada.nombre} como origen',
        excludeSemantics: true,
        child: const Text('Como origen', textAlign: TextAlign.center),
      ),
    );
    final botonDestino = OutlinedButton(
      onPressed: () => estado.usarComoDestino(parada.id),
      child: Semantics(
        label: 'Usar ${parada.nombre} como destino',
        excludeSemantics: true,
        child: const Text('Como destino', textAlign: TextAlign.center),
      ),
    );

    return Pantalla(
      titulo: parada.nombre,
      volverA: volverA,
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const TituloSeccion('Líneas que pasan'),
          const SizedBox(height: 12),
          for (final l in lineas) ...[
            Builder(
              builder: (context) {
                final i = l.paradas.indexOf(parada.id);
                final esFinal = i == l.paradas.length - 1;
                final horas = l.pasosPor(i, desde: ahora).map(hhmm).toList();
                final titulo = esFinal
                    ? '${l.nombre} · final de línea'
                    : '${l.nombre} · a ${l.destino}';
                final linea2 = esFinal
                    ? (horas.isEmpty
                          ? 'Sin más llegadas hoy'
                          : 'Llegadas: ${horas.join(' · ')}')
                    : textoProximos(horas);
                return MergeSemantics(
                  child: Caja(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: tt.titleMedium),
                        const SizedBox(height: 4),
                        Text(linea2, style: tt.bodyLarge),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const TituloSeccion('Usar esta parada'),
          const SizedBox(height: 12),
          if (apilar) ...[
            botonOrigen,
            const SizedBox(height: 12),
            botonDestino,
          ] else
            Row(
              children: [
                Expanded(child: botonOrigen),
                const SizedBox(width: 16),
                Expanded(child: botonDestino),
              ],
            ),
          const AvisoHorariosTeoricos(),
        ],
      ),
    );
  }
}
