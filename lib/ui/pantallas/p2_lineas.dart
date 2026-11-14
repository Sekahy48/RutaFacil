// P2 · Líneas.

import 'package:flutter/material.dart';

import '../../data/datos_mock.dart';
import '../comunes.dart';
import '../tema.dart';
import 'p3_detalle_linea.dart';

class PantallaLineas extends StatelessWidget {
  const PantallaLineas({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Pantalla(
      titulo: 'Líneas',
      cuerpo: ListView(
        children: [
          for (final l in kLineas)
            FilaNavegable(
              titulo: l.nombre,
              inicio: EtiquetaLinea(l.id),
              subtitulo: '${l.resumen}\nCada ${l.frecuencia} min',
              etiqueta:
                  '${l.nombre}. ${l.resumen}. Cada ${l.frecuencia} '
                  'minutos. Abrir paradas y horarios.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PantallaDetalleLinea(linea: l),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Datos de ejemplo de la zona de prueba',
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(
                color: context.paleta.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
