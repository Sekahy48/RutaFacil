// Sistema visual de RutaFácil (semana 4).
//
// Todos los colores, medidas y estilos de texto de la app están aquí como
// constantes con nombre. Las pantallas no usan colores sueltos: leen la
// paleta con `context.paleta` o el `ColorScheme` del tema.
//
// Los hex de las paletas los lee `docs/scripts/contrastes.py` (busca las
// líneas `const kNormal… = Color(0xFF……)` y `const kAlto… = Color(0xFF……)`),
// así que no cambies el formato de esas líneas.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Colores del tema normal (hex medidos; no cambiar sin revisar contrastes).
// ---------------------------------------------------------------------------
const kNormalFondo = Color(0xFFF1F1EE);
const kNormalSuperficie = Color(0xFFF8F8F6);
const kNormalTexto = Color(0xFF1B1F23);
const kNormalTextoSecundario = Color(0xFF444B52);
const kNormalAcento = Color(0xFF2C5F6F);
const kNormalSobreAcento = Color(0xFFF8F8F6);
const kNormalBorde = Color(0xFF6A7178);
const kNormalFoco = Color(0xFF1A4FB5);
const kNormalError = Color(0xFFA12626);
const kNormalExito = Color(0xFF1F6B36);
const kNormalAvisoFondo = Color(0xFFFFF1CC);
const kNormalAvisoBorde = Color(0xFF8A5A00);
const kNormalPestanaInactiva = Color(0xFFE9E9E4);
const kNormalMapa = Color(0xFFE8E8E4);

// ---------------------------------------------------------------------------
// Colores del tema de alto contraste (misma estructura). La especificación
// solo da fondo, textos, acento, error y éxito: el resto de huecos reutiliza
// esos mismos valores para no introducir colores nuevos.
// ---------------------------------------------------------------------------
const kAltoFondo = Color(0xFF121214);
const kAltoSuperficie = Color(0xFF121214);
const kAltoTexto = Color(0xFFF2F2F2);
const kAltoTextoSecundario = Color(0xFFD4D4D4);
const kAltoAcento = Color(0xFFE8D27F);
const kAltoSobreAcento = Color(0xFF121214);
const kAltoBorde = Color(0xFFE8D27F);
const kAltoFoco = Color(0xFFE8D27F);
const kAltoError = Color(0xFFFF9E9E);
const kAltoExito = Color(0xFF8DF0A0);
const kAltoAvisoFondo = Color(0xFF121214);
const kAltoAvisoBorde = Color(0xFFE8D27F);
const kAltoPestanaInactiva = Color(0xFF121214);
const kAltoMapa = Color(0xFF121214);

/// Pines (etiquetas de parada) del mapa. Son alias de los colores de cada
/// tema (sin hex nuevos):
///  - normal: claros (superficie) con texto y borde oscuros de 2 dp;
///  - alto contraste: fondo AC con texto AC y borde de acento de 3 dp.
const kNormalPinFondo = kNormalSuperficie;
const kNormalPinTexto = kNormalTexto;
const kNormalPinBorde = kNormalTexto;
const double kNormalPinGrosor = kBorde;
const kAltoPinFondo = kAltoFondo;
const kAltoPinTexto = kAltoTexto;
const kAltoPinBorde = kAltoAcento;
const double kAltoPinGrosor = kBordeEstado;

/// Oscurecimiento de las teselas del mapa en alto contraste (P6): saturación
/// que se conserva (0 = gris), factor tras invertir y desplazamiento de brillo
/// (0–255).
const double kMapaOscuroSaturacion = 0.2;
const double kMapaOscuroEscala = 0.9;
const double kMapaOscuroDesplazamiento = 18;

// ---------------------------------------------------------------------------
// Medidas.
// ---------------------------------------------------------------------------

/// Unidad base de espaciado (8 dp).
const double kEspacio = 8;

/// Separación mínima entre «Salir» / «Terminar trayecto» y sus vecinos.
const double kEspacioCritico = 24;

/// Radio de esquinas de botones, tarjetas, campos, pines y opciones.
const double kRadio = 12;

/// Grosor de borde de botones, campos, tarjetas y pines.
const double kBorde = 2;

/// Grosor del borde de estado (error, aviso) y del anillo de foco.
const double kBordeEstado = 3;

/// Alto del botón principal (ancho completo).
const double kAltoBotonPrincipal = 56;

/// Área táctil mínima.
const double kTactilMinimo = 48;

/// Alto mínimo de los campos de texto.
const double kAltoCampo = 56;

const BorderRadius kRadioBorde = BorderRadius.all(Radius.circular(kRadio));

// ---------------------------------------------------------------------------
// Tipografía (sp; escala con el texto del sistema, sin límite).
// ---------------------------------------------------------------------------
const kFamilia = 'Geist';

/// Geist Serif solo para los títulos de pantalla (28 sp). Si no se viera bien,
/// poner a `false` y los títulos pasan a Geist 600.
const bool kTitulosConSerif = true;
const kFamiliaTitulo = kTitulosConSerif ? 'GeistSerif' : kFamilia;

/// Título de pantalla: 28/34, Geist Serif 400.
const kEstiloTitulo = TextStyle(
  fontFamily: kFamiliaTitulo,
  fontSize: 28,
  height: 34 / 28,
  fontWeight: kTitulosConSerif ? FontWeight.w400 : FontWeight.w600,
);

/// Subtítulo: 20/28, Geist 600.
const kEstiloSubtitulo = TextStyle(
  fontFamily: kFamilia,
  fontSize: 20,
  height: 28 / 20,
  fontWeight: FontWeight.w600,
);

/// Cuerpo: 16/24, Geist 400.
const kEstiloCuerpo = TextStyle(
  fontFamily: kFamilia,
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w400,
);

/// Botones y etiquetas: 16/24, Geist 600.
const kEstiloEtiqueta = TextStyle(
  fontFamily: kFamilia,
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w600,
);

/// Texto pequeño: 14/20, Geist 400 (nada por debajo de 14 sp).
const kEstiloPequeno = TextStyle(
  fontFamily: kFamilia,
  fontSize: 14,
  height: 20 / 14,
  fontWeight: FontWeight.w400,
);

// ---------------------------------------------------------------------------
// Paleta como extensión del tema.
// ---------------------------------------------------------------------------
@immutable
class Paleta extends ThemeExtension<Paleta> {
  const Paleta({
    required this.altoContraste,
    required this.fondo,
    required this.superficie,
    required this.texto,
    required this.textoSecundario,
    required this.acento,
    required this.sobreAcento,
    required this.borde,
    required this.foco,
    required this.error,
    required this.exito,
    required this.avisoFondo,
    required this.avisoBorde,
    required this.pestanaInactiva,
    required this.mapa,
    required this.pinFondo,
    required this.pinTexto,
    required this.pinBorde,
    required this.pinGrosor,
  });

  final bool altoContraste;
  final Color fondo;
  final Color superficie;
  final Color texto;
  final Color textoSecundario;
  final Color acento;
  final Color sobreAcento;
  final Color borde;
  final Color foco;
  final Color error;
  final Color exito;
  final Color avisoFondo;
  final Color avisoBorde;
  final Color pestanaInactiva;
  final Color mapa;

  /// Pin (etiqueta de parada) del mapa.
  final Color pinFondo;
  final Color pinTexto;
  final Color pinBorde;
  final double pinGrosor;

  /// Opacidad del estado desactivado (atenuado; WCAG no exige contraste
  /// a los controles desactivados, que además se anuncian «no disponible»).
  static const double opacidadDesactivado = 0.45;

  Color get desactivado => texto.withValues(alpha: opacidadDesactivado);

  @override
  Paleta copyWith() => this;

  @override
  Paleta lerp(Paleta? other, double t) => t < 0.5 ? this : (other ?? this);
}

const kPaletaNormal = Paleta(
  altoContraste: false,
  fondo: kNormalFondo,
  superficie: kNormalSuperficie,
  texto: kNormalTexto,
  textoSecundario: kNormalTextoSecundario,
  acento: kNormalAcento,
  sobreAcento: kNormalSobreAcento,
  borde: kNormalBorde,
  foco: kNormalFoco,
  error: kNormalError,
  exito: kNormalExito,
  avisoFondo: kNormalAvisoFondo,
  avisoBorde: kNormalAvisoBorde,
  pestanaInactiva: kNormalPestanaInactiva,
  mapa: kNormalMapa,
  pinFondo: kNormalPinFondo,
  pinTexto: kNormalPinTexto,
  pinBorde: kNormalPinBorde,
  pinGrosor: kNormalPinGrosor,
);

const kPaletaAltoContraste = Paleta(
  altoContraste: true,
  fondo: kAltoFondo,
  superficie: kAltoSuperficie,
  texto: kAltoTexto,
  textoSecundario: kAltoTextoSecundario,
  acento: kAltoAcento,
  sobreAcento: kAltoSobreAcento,
  borde: kAltoBorde,
  foco: kAltoFoco,
  error: kAltoError,
  exito: kAltoExito,
  avisoFondo: kAltoAvisoFondo,
  avisoBorde: kAltoAvisoBorde,
  pestanaInactiva: kAltoPestanaInactiva,
  mapa: kAltoMapa,
  pinFondo: kAltoPinFondo,
  pinTexto: kAltoPinTexto,
  pinBorde: kAltoPinBorde,
  pinGrosor: kAltoPinGrosor,
);

extension PaletaDeContexto on BuildContext {
  Paleta get paleta => Theme.of(this).extension<Paleta>() ?? kPaletaNormal;
}

// ---------------------------------------------------------------------------
// Forma con anillo de foco: borde normal y, por fuera, un hueco del color del
// fondo y un anillo de 3 dp del color de foco. Así el foco se ve también en
// botones rellenos del mismo color que el foco (alto contraste).
// ---------------------------------------------------------------------------
class FormaConFoco extends RoundedRectangleBorder {
  const FormaConFoco({
    super.side,
    super.borderRadius = kRadioBorde,
    required this.foco,
    required this.hueco,
  });

  final Color foco;
  final Color hueco;

  @override
  FormaConFoco copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) {
    return FormaConFoco(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      foco: foco,
      hueco: hueco,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    pintarAnilloFoco(
      canvas,
      borderRadius.resolve(textDirection).toRRect(rect),
      foco: foco,
      hueco: hueco,
    );
  }
}

/// Dibuja el anillo de foco por fuera de [rr].
void pintarAnilloFoco(
  Canvas canvas,
  RRect rr, {
  required Color foco,
  required Color hueco,
}) {
  canvas.drawRRect(
    rr.inflate(1),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = hueco,
  );
  canvas.drawRRect(
    rr.inflate(2 + kBordeEstado / 2),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kBordeEstado
      ..color = foco,
  );
}

// ---------------------------------------------------------------------------
// Tema.
// ---------------------------------------------------------------------------
TextTheme _textos(Color texto) {
  final titulo = kEstiloTitulo.copyWith(color: texto);
  final sub = kEstiloSubtitulo.copyWith(color: texto);
  final cuerpo = kEstiloCuerpo.copyWith(color: texto);
  final etiqueta = kEstiloEtiqueta.copyWith(color: texto);
  final pequeno = kEstiloPequeno.copyWith(color: texto);
  return TextTheme(
    displayLarge: titulo,
    displayMedium: titulo,
    displaySmall: titulo,
    headlineLarge: titulo,
    headlineMedium: titulo,
    headlineSmall: titulo,
    titleLarge: sub,
    titleMedium: sub,
    titleSmall: etiqueta,
    bodyLarge: cuerpo,
    bodyMedium: cuerpo,
    bodySmall: pequeno,
    labelLarge: etiqueta,
    labelMedium: etiqueta.copyWith(fontSize: 14, height: 20 / 14),
    labelSmall: etiqueta.copyWith(fontSize: 14, height: 20 / 14),
  );
}

ThemeData construirTema({required bool altoContraste}) {
  final p = altoContraste ? kPaletaAltoContraste : kPaletaNormal;
  final textos = _textos(p.texto);

  final esquema = ColorScheme(
    brightness: altoContraste ? Brightness.dark : Brightness.light,
    primary: p.acento,
    onPrimary: p.sobreAcento,
    primaryContainer: p.acento,
    onPrimaryContainer: p.sobreAcento,
    secondary: p.acento,
    onSecondary: p.sobreAcento,
    secondaryContainer: p.acento,
    onSecondaryContainer: p.sobreAcento,
    tertiary: p.acento,
    onTertiary: p.sobreAcento,
    error: p.error,
    onError: p.superficie,
    surface: p.fondo,
    onSurface: p.texto,
    onSurfaceVariant: p.textoSecundario,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: p.superficie,
    surfaceContainerLow: p.superficie,
    surfaceContainer: p.superficie,
    surfaceContainerHigh: p.superficie,
    surfaceContainerHighest: p.superficie,
    outline: p.borde,
    outlineVariant: p.borde,
    inverseSurface: p.texto,
    onInverseSurface: p.fondo,
    inversePrimary: p.superficie,
    shadow: Colors.transparent,
    scrim: p.fondo.withValues(alpha: 0.7),
  );

  const forma = RoundedRectangleBorder(borderRadius: kRadioBorde);
  final formaFoco = FormaConFoco(foco: p.foco, hueco: p.fondo);

  WidgetStateProperty<OutlinedBorder> formaBoton() =>
      WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused) ? formaFoco : forma,
      );

  // Pulsado: un velo leve del color del texto del botón.
  WidgetStateProperty<Color?> velo(Color c) => WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.pressed) ? c.withValues(alpha: 0.16) : null,
  );

  const relleno = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  final botonPrincipal = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? p.superficie : p.acento,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? p.desactivado : p.sobreAcento,
    ),
    overlayColor: velo(p.sobreAcento),
    side: WidgetStateProperty.resolveWith(
      (s) => BorderSide(
        color: s.contains(WidgetState.disabled) ? p.desactivado : p.acento,
        width: kBorde,
      ),
    ),
    minimumSize: const WidgetStatePropertyAll(
      Size(kTactilMinimo, kAltoBotonPrincipal),
    ),
    padding: const WidgetStatePropertyAll(relleno),
    textStyle: WidgetStatePropertyAll(kEstiloEtiqueta),
    shape: formaBoton(),
    elevation: const WidgetStatePropertyAll(0),
  );

  final botonSecundario = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(p.superficie),
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? p.desactivado : p.acento,
    ),
    overlayColor: velo(p.acento),
    side: WidgetStateProperty.resolveWith(
      (s) => BorderSide(
        color: s.contains(WidgetState.disabled) ? p.desactivado : p.acento,
        width: kBorde,
      ),
    ),
    minimumSize: const WidgetStatePropertyAll(
      Size(kTactilMinimo, kTactilMinimo),
    ),
    padding: const WidgetStatePropertyAll(relleno),
    textStyle: WidgetStatePropertyAll(kEstiloEtiqueta),
    shape: formaBoton(),
    elevation: const WidgetStatePropertyAll(0),
  );

  OutlineInputBorder bordeCampo(Color c, double w) => OutlineInputBorder(
    borderRadius: kRadioBorde,
    borderSide: BorderSide(color: c, width: w),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    fontFamily: kFamilia,
    textTheme: textos,
    primaryTextTheme: textos,
    scaffoldBackgroundColor: p.fondo,
    canvasColor: p.fondo,
    cardColor: p.superficie,
    dividerColor: p.borde,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    // El foco se marca con el anillo de [FormaConFoco], no con un velo.
    focusColor: Colors.transparent,
    hoverColor: Colors.transparent,
    highlightColor: p.texto.withValues(alpha: 0.08),
    splashColor: p.texto.withValues(alpha: 0.12),
    extensions: [p],
  );

  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(style: botonPrincipal),
    elevatedButtonTheme: ElevatedButtonThemeData(style: botonPrincipal),
    outlinedButtonTheme: OutlinedButtonThemeData(style: botonSecundario),
    textButtonTheme: TextButtonThemeData(style: botonSecundario),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(kTactilMinimo + 8, kTactilMinimo + 8),
        ),
        foregroundColor: WidgetStatePropertyAll(p.acento),
        backgroundColor: WidgetStatePropertyAll(p.superficie),
        overlayColor: velo(p.acento),
        side: WidgetStatePropertyAll(
          BorderSide(color: p.acento, width: kBorde),
        ),
        shape: formaBoton(),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.acento,
      foregroundColor: p.sobreAcento,
      shape: forma,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.superficie,
      hintStyle: kEstiloCuerpo.copyWith(color: p.textoSecundario),
      labelStyle: kEstiloEtiqueta.copyWith(color: p.texto),
      floatingLabelStyle: kEstiloEtiqueta.copyWith(color: p.texto),
      errorStyle: kEstiloEtiqueta.copyWith(color: p.error),
      errorMaxLines: 4,
      constraints: const BoxConstraints(minHeight: kAltoCampo),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: bordeCampo(p.borde, kBorde),
      enabledBorder: bordeCampo(p.borde, kBorde),
      disabledBorder: bordeCampo(p.desactivado, kBorde),
      focusedBorder: bordeCampo(p.foco, kBordeEstado),
      errorBorder: bordeCampo(p.error, kBordeEstado),
      focusedErrorBorder: bordeCampo(p.error, kBordeEstado),
      suffixIconColor: p.acento,
      prefixIconColor: p.texto,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.texto,
      selectionColor: p.acento.withValues(alpha: 0.3),
      selectionHandleColor: p.acento,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.sobreAcento : p.borde,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.acento : p.superficie,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.acento : p.borde,
      ),
      trackOutlineWidth: const WidgetStatePropertyAll(kBorde),
      thumbIcon: WidgetStateProperty.resolveWith(
        (s) => Icon(
          s.contains(WidgetState.selected) ? Icons.check : Icons.close,
          color: s.contains(WidgetState.selected) ? p.acento : p.superficie,
        ),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.acento,
      circularTrackColor: Colors.transparent,
    ),
    iconTheme: IconThemeData(color: p.texto),
    dialogTheme: DialogThemeData(
      backgroundColor: p.superficie,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: kEstiloSubtitulo.copyWith(color: p.texto),
      contentTextStyle: kEstiloCuerpo.copyWith(color: p.texto),
      shape: RoundedRectangleBorder(
        borderRadius: kRadioBorde,
        side: BorderSide(color: p.borde, width: kBorde),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: kEstiloPequeno.copyWith(color: p.texto),
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: kRadioBorde,
        border: Border.all(color: p.borde, width: kBorde),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.texto,
      contentTextStyle: kEstiloCuerpo.copyWith(color: p.fondo),
      shape: forma,
    ),
    dividerTheme: DividerThemeData(color: p.borde, thickness: 1),
    chipTheme: const ChipThemeData(shape: forma),
  );
}
