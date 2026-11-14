// Piezas de interfaz reutilizadas por todas las pantallas.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'tema.dart';

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

  /// Acción a la derecha (p. ej. «Salir»); se separa 24 dp del título.
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Material(
      color: p.superficie,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.borde, width: kBorde),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              const SizedBox(width: 2 * kEspacio),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: kEspacio),
                child: Semantics(
                  header: true,
                  child: Text(
                    titulo,
                    style: kEstiloTitulo.copyWith(color: p.texto),
                  ),
                ),
              ),
            ),
            if (accion != null) ...[
              const SizedBox(width: kEspacioCritico),
              accion!,
            ],
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
    this.grosor = kBorde,
    this.colorBorde,
    this.colorFondo,
    this.padding = const EdgeInsets.all(2 * kEspacio),
  });

  final Widget child;
  final double grosor;
  final Color? colorBorde;
  final Color? colorFondo;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorFondo ?? p.superficie,
        borderRadius: kRadioBorde,
        border: Border.all(color: colorBorde ?? p.borde, width: grosor),
      ),
      child: child,
    );
  }
}

/// Icono ⚠ decorativo (el texto que lo acompaña ya dice «Error» o «AVISO»).
class IconoAtencion extends StatelessWidget {
  const IconoAtencion({super.key, this.color, this.tamano = 28});
  final Color? color;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        Icons.warning_amber_rounded,
        size: tamano,
        color: color ?? context.paleta.texto,
      ),
    );
  }
}

/// Línea de error: ⚠ + «Error: …» en el color de error. No depende del
/// color: lleva icono y prefijo de texto.
class LineaError extends StatelessWidget {
  const LineaError(this.mensaje, {super.key});

  /// Mensaje sin el prefijo «Error:».
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconoAtencion(color: p.error, tamano: 24),
        const SizedBox(width: kEspacio),
        Expanded(
          child: Text(
            'Error: $mensaje',
            style: kEstiloEtiqueta.copyWith(color: p.error),
          ),
        ),
      ],
    );
  }
}

/// Caja de error: borde de 3 dp + ⚠ + «Error: …» + cómo corregirlo.
class CajaError extends StatelessWidget {
  const CajaError(this.mensaje, {super.key});

  /// Mensaje sin el prefijo «Error:».
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      liveRegion: true,
      child: Caja(
        grosor: kBordeEstado,
        colorBorde: p.error,
        child: LineaError(mensaje),
      ),
    );
  }
}

/// Texto de éxito: «✓» + texto en el color de éxito.
class TextoExito extends StatelessWidget {
  const TextoExito(this.texto, {super.key, this.estilo});
  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Text(
      '✓ $texto',
      style: (estilo ?? kEstiloSubtitulo).copyWith(color: context.paleta.exito),
    );
  }
}

/// Etiqueta neutra de línea («L1»…«L4»). Las líneas se identifican por este
/// texto, nunca por color.
class EtiquetaLinea extends StatelessWidget {
  const EtiquetaLinea(this.idLinea, {super.key});

  /// Id de la línea («L1»…).
  final String idLinea;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ExcludeSemantics(
      child: Container(
        // Ancho mínimo común para que «L1» y «L4» alineen igual en las listas.
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: kEspacio, vertical: 2),
        decoration: BoxDecoration(
          color: p.superficie,
          borderRadius: kRadioBorde,
          border: Border.all(color: p.texto, width: kBorde),
        ),
        child: Text(
          idLinea,
          textAlign: TextAlign.center,
          style: kEstiloEtiqueta.copyWith(color: p.texto),
        ),
      ),
    );
  }
}

/// Zona táctil con anillo de foco visible (3 dp, color de foco). Si
/// [anilloDentro] es true el anillo se dibuja por dentro (filas a todo el
/// ancho, donde por fuera quedaría recortado).
class Tocable extends StatefulWidget {
  const Tocable({
    super.key,
    required this.onTap,
    required this.child,
    this.radio = kRadioBorde,
    this.anilloDentro = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius radio;
  final bool anilloDentro;

  @override
  State<Tocable> createState() => _TocableState();
}

class _TocableState extends State<Tocable> {
  var _foco = false;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: widget.radio,
      onFocusChange: (f) => setState(() => _foco = f),
      child: CustomPaint(
        foregroundPainter: _foco
            ? _PintorFoco(
                foco: p.foco,
                hueco: p.fondo,
                radio: widget.radio,
                dentro: widget.anilloDentro,
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

class _PintorFoco extends CustomPainter {
  _PintorFoco({
    required this.foco,
    required this.hueco,
    required this.radio,
    required this.dentro,
  });

  final Color foco;
  final Color hueco;
  final BorderRadius radio;
  final bool dentro;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = radio.toRRect(Offset.zero & size);
    if (dentro) {
      pintarAnilloFoco(
        canvas,
        rr.deflate(2 + kBordeEstado),
        foco: foco,
        hueco: hueco,
      );
    } else {
      pintarAnilloFoco(canvas, rr, foco: foco, hueco: hueco);
    }
  }

  @override
  bool shouldRepaint(_PintorFoco old) =>
      old.foco != foco || old.hueco != hueco || old.dentro != dentro;
}

/// Fila de lista que se abre con un toque: título, subtítulo y «›».
class FilaNavegable extends StatelessWidget {
  const FilaNavegable({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.inicio,
    required this.etiqueta,
    required this.onTap,
  });

  final String titulo;
  final String? subtitulo;

  /// Widget opcional a la izquierda del título (p. ej. [EtiquetaLinea]).
  final Widget? inicio;

  /// Texto completo que lee TalkBack (p. ej. "Línea 1, Estación – Hospital,
  /// abrir detalle").
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final p = context.paleta;
    return Semantics(
      container: true,
      button: true,
      label: etiqueta,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: p.superficie,
        child: Tocable(
          onTap: onTap,
          radio: BorderRadius.zero,
          anilloDentro: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 2 * kEspacio,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.borde, width: 1)),
            ),
            child: Row(
              children: [
                if (inicio != null) ...[
                  inicio!,
                  const SizedBox(width: 2 * kEspacio),
                ],
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
                Icon(Icons.chevron_right, size: 32, color: p.texto),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de texto con la etiqueta visible ENCIMA (no solo como pista) y el
/// error debajo con ⚠ y «Error:».
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.focusNode,
    this.pista,
    this.error,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onBorrar,
  });

  final String etiqueta;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? pista;

  /// Mensaje de error sin el prefijo «Error:».
  final String? error;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Si no es null y hay texto, muestra el botón «Borrar [etiqueta]».
  final VoidCallback? onBorrar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TalkBack ya lee la etiqueta desde el propio campo (labelText
        // semántico de abajo); aquí solo se muestra.
        ExcludeSemantics(
          child: Text(
            etiqueta,
            style: kEstiloEtiqueta.copyWith(color: p.texto),
          ),
        ),
        const SizedBox(height: kEspacio),
        Semantics(
          label: etiqueta,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: kEstiloCuerpo.copyWith(color: p.texto),
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: pista,
              hintMaxLines: 3,
              error: error == null ? null : LineaError(error!),
              suffixIcon: onBorrar == null || controller.text.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        tooltip: 'Borrar ${etiqueta.toLowerCase()}',
                        style: IconButton.styleFrom(
                          side: BorderSide.none,
                          minimumSize: const Size(kTactilMinimo, kTactilMinimo),
                        ),
                        icon: const Icon(Icons.close),
                        onPressed: onBorrar,
                      ),
                    ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(
        vertical: 2 * kEspacio,
        horizontal: 20,
      ),
      child: Text(
        'Horarios teóricos (sin tiempo real)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: context.paleta.textoSecundario),
      ),
    );
  }
}

/// Texto de un botón. Si [activo] es false, TalkBack lo anuncia como
/// «…, no disponible» (además de verse atenuado por el tema).
Widget textoBoton(String texto, {bool activo = true, String? etiqueta}) {
  final dicho = etiqueta ?? texto;
  return Semantics(
    label: activo ? dicho : '$dicho, no disponible',
    excludeSemantics: true,
    child: Text(texto, textAlign: TextAlign.center),
  );
}

/// Texto de los próximos pasos: "Próximos: 08:35 · 08:50 · 09:05".
String textoProximos(List<String> horas) =>
    horas.isEmpty ? 'Sin más pasos hoy' : 'Próximos: ${horas.join(' · ')}';

/// Versión para lector de pantalla (sin el separador «·»).
String textoProximosHablado(List<String> horas) =>
    horas.isEmpty ? 'Sin más pasos hoy' : 'Próximos: ${horas.join(', ')}';
