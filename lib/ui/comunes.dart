// Piezas de interfaz reutilizadas por todas las pantallas.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Anuncia [mensaje] al lector de pantalla (TalkBack).
void anunciar(BuildContext context, String mensaje) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    mensaje,
    Directionality.of(context),
    assertiveness: Assertiveness.assertive,
  );
}

/// Cabecera de pantalla: título (marcado como encabezado), botón de volver
/// opcional y acción opcional a la derecha. Crece con el tamaño del texto.
class Cabecera extends StatelessWidget {
  const Cabecera({super.key, required this.titulo, this.volverA, this.accion});

  final String titulo;

  /// Si no es null, muestra «‹ volverA» que cierra la pantalla actual.
  final String? volverA;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.surfaceContainerHighest,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: esquema.outline, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            if (volverA != null) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Semantics(
                  label: 'Volver a $volverA',
                  excludeSemantics: true,
                  child: Text('‹ $volverA'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Semantics(
                  header: true,
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ),
            if (accion != null) ...[const SizedBox(width: 12), accion!],
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de pantalla: cabecera + cuerpo.
class Pantalla extends StatelessWidget {
  const Pantalla({
    super.key,
    required this.titulo,
    required this.cuerpo,
    this.volverA,
    this.accion,
  });

  final String titulo;
  final Widget cuerpo;
  final String? volverA;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Cabecera(titulo: titulo, volverA: volverA, accion: accion),
            Expanded(child: cuerpo),
          ],
        ),
      ),
    );
  }
}

/// Título de sección (encabezado para el lector de pantalla).
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// Caja con borde (tarjeta del wireframe).
class Caja extends StatelessWidget {
  const Caja({
    super.key,
    required this.child,
    this.grosor = 1.5,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double grosor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: esquema.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: esquema.outline, width: grosor),
      ),
      child: child,
    );
  }
}

/// Fila de lista que se abre con un toque: título, subtítulo y «›».
class FilaNavegable extends StatelessWidget {
  const FilaNavegable({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.etiqueta,
    required this.onTap,
  });

  final String titulo;
  final String? subtitulo;

  /// Texto completo que lee TalkBack (p. ej. "Línea 1, Estación – Hospital,
  /// abrir detalle").
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      label: etiqueta,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: esquema.surfaceContainerLowest,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: esquema.outlineVariant, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(titulo, style: tt.titleMedium),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitulo!, style: tt.bodyLarge),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, size: 32, color: esquema.onSurface),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tocar en una zona vacía quita el foco del campo de texto y cierra el
/// teclado (los controles internos siguen recibiendo sus toques).
class QuitarFocoAlTocar extends StatelessWidget {
  const QuitarFocoAlTocar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}

/// Nota fija sobre los horarios.
class AvisoHorariosTeoricos extends StatelessWidget {
  const AvisoHorariosTeoricos({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Text(
        'Horarios teóricos (sin tiempo real)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Texto de los próximos pasos: "Próximos: 08:35 · 08:50 · 09:05".
String textoProximos(List<String> horas) =>
    horas.isEmpty ? 'Sin más pasos hoy' : 'Próximos: ${horas.join(' · ')}';

/// Versión para lector de pantalla (sin el separador «·»).
String textoProximosHablado(List<String> horas) =>
    horas.isEmpty ? 'Sin más pasos hoy' : 'Próximos: ${horas.join(', ')}';
