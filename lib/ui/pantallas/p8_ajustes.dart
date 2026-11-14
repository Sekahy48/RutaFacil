// P8 · Ajustes (estado en memoria; no se guarda al cerrar la app).

import 'package:flutter/material.dart';

import '../../estado.dart';
import '../comunes.dart';
import '../tema.dart';

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Pantalla(
      titulo: 'Ajustes',
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _Conmutador(
            titulo: 'Tema de alto contraste',
            valor: estado.altoContraste,
          ),
          const SizedBox(height: 16),
          const _Antelacion(),
          const SizedBox(height: 16),
          _Conmutador(titulo: 'Sonido del aviso', valor: estado.sonidoAviso),
          const SizedBox(height: 20),
          Text(
            'La vibración y el mensaje del aviso siempre están activados.',
            style: tt.bodyLarge?.copyWith(
              color: context.paleta.textoSecundario,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Los ajustes no se guardan al cerrar la app (prototipo).',
            style: tt.bodyMedium?.copyWith(
              color: context.paleta.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con conmutador. El estado se dice con texto
/// («Estado: activado») y con un icono ✓ en el control, no solo con color.
class _Conmutador extends StatelessWidget {
  const _Conmutador({required this.titulo, required this.valor});

  final String titulo;
  final ValueNotifier<bool> valor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ValueListenableBuilder<bool>(
      valueListenable: valor,
      builder: (context, activo, _) => Caja(
        padding: EdgeInsets.zero,
        child: MergeSemantics(
          child: Tocable(
            onTap: () => valor.value = !activo,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: tt.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: ${activo ? 'activado' : 'desactivado'}',
                          style: tt.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // El foco lo lleva la tarjeta entera (con anillo visible).
                  ExcludeFocus(
                    child: Switch(
                      value: activo,
                      onChanged: (v) => valor.value = v,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Antelacion extends StatelessWidget {
  const _Antelacion();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final p = context.paleta;
    return ValueListenableBuilder<int>(
      valueListenable: estado.antelacion,
      builder: (context, actual, _) => Caja(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('Avisar con antelación', style: tt.titleMedium),
            ),
            const SizedBox(height: 4),
            Text('Paradas antes de la de bajada', style: tt.bodyLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 2 * kEspacio,
              runSpacing: 2 * kEspacio,
              children: [
                for (final n in [1, 2, 3])
                  Semantics(
                    container: true,
                    inMutuallyExclusiveGroup: true,
                    checked: n == actual,
                    button: true,
                    label: n == 1 ? '1 parada antes' : '$n paradas antes',
                    onTap: () => estado.antelacion.value = n,
                    excludeSemantics: true,
                    // Elegida: relleno de acento + «✓». No elegidas: solo borde.
                    child: n == actual
                        ? FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(88, 56),
                            ),
                            child: Text(
                              '✓ $n',
                              style: tt.titleLarge?.copyWith(
                                color: p.sobreAcento,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => estado.antelacion.value = n,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(88, 56),
                            ),
                            child: Text(
                              '$n',
                              style: tt.titleLarge?.copyWith(color: p.acento),
                            ),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
