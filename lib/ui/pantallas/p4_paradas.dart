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
              child: TextField(
                controller: _ctrl,
                style: tt.bodyLarge,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Buscar parada',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: tt.titleMedium,
                  hintText: 'Escribe el nombre',
                  suffixIcon: _ctrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda',
                          style: IconButton.styleFrom(
                            side: BorderSide.none,
                            backgroundColor: Colors.transparent,
                          ),
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_ctrl.clear),
                        ),
                ),
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
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No hay paradas con ese nombre.',
                  style: tt.bodyLarge,
                ),
              ),
            for (final p in lista)
              FilaNavegable(
                titulo: p.nombre,
                subtitulo:
                    'Líneas: ${lineasDeParada(p.id).map((l) => l.id.substring(1)).join(', ')}',
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
