// P4 · Paradas: buscador + lista (equivalente accesible del mapa).
// Funciona sin conexión: solo usa datos locales.

import 'package:flutter/material.dart';

import '../../data/datos_mock.dart';
import '../comunes.dart';
import 'p5_detalle_parada.dart';

class PantallaParadas extends StatefulWidget {
  const PantallaParadas({super.key});

  @override
  State<PantallaParadas> createState() => _PantallaParadasState();
}

class _PantallaParadasState extends State<PantallaParadas> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final lista = buscarParadas(_ctrl.text);

    return Pantalla(
      titulo: 'Paradas',
      cuerpo: QuitarFocoAlTocar(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: CampoTexto(
                etiqueta: 'Buscar parada',
                controller: _ctrl,
                pista: 'Escribe el nombre',
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onBorrar: () => setState(_ctrl.clear),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  lista.length == 1 ? '1 parada' : '${lista.length} paradas',
                  style: tt.bodyLarge,
                ),
              ),
            ),
            if (lista.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: CajaError(
                  'no hay ninguna parada que contenga «${_ctrl.text.trim()}». '
                  'Revisa cómo está escrito (las tildes no importan) o borra '
                  'la búsqueda para ver todas las paradas.',
                ),
              ),
            for (final p in lista)
              FilaNavegable(
                titulo: p.nombre,
                subtitulo:
                    'Líneas: ${lineasDeParada(p.id).map((l) => l.id).join(', ')}',
                etiqueta:
                    'Parada ${p.nombre}. Líneas '
                    '${lineasDeParada(p.id).map((l) => l.id.substring(1)).join(', ')}. '
                    'Abrir detalle.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PantallaDetalleParada(parada: p, volverA: 'Paradas'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
