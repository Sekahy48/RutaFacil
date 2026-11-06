// Tema neutro en escala de grises y tema de alto contraste (negro/blanco).
//
// Contrastes (aprox., WCAG):
//  - Texto #1A1A1A sobre #FFFFFF: 17,4:1; sobre #F7F7F7: 16,2:1.
//  - Texto secundario #4D4D4D sobre #F7F7F7: 7,9:1.
//  - Texto blanco sobre botón #3D3D3D: 11,0:1.
//  - Alto contraste: blanco sobre negro 21:1.

import 'package:flutter/material.dart';

ThemeData construirTema({required bool altoContraste}) {
  final fondo = altoContraste ? Colors.black : const Color(0xFFF7F7F7);
  final tarjeta = altoContraste ? Colors.black : Colors.white;
  final cabecera = altoContraste ? Colors.black : const Color(0xFFE6E6E6);
  final texto = altoContraste ? Colors.white : const Color(0xFF1A1A1A);
  final textoSec = altoContraste ? Colors.white : const Color(0xFF4D4D4D);
  final borde = altoContraste ? Colors.white : const Color(0xFF212121);
  final primario = altoContraste ? Colors.white : const Color(0xFF3D3D3D);
  final sobrePrimario = altoContraste ? Colors.black : Colors.white;

  final esquema = ColorScheme(
    brightness: altoContraste ? Brightness.dark : Brightness.light,
    primary: primario,
    onPrimary: sobrePrimario,
    secondary: primario,
    onSecondary: sobrePrimario,
    error: texto,
    onError: fondo,
    surface: fondo,
    onSurface: texto,
    onSurfaceVariant: textoSec,
    surfaceContainerLowest: tarjeta,
    surfaceContainerLow: tarjeta,
    surfaceContainer: cabecera,
    surfaceContainerHigh: cabecera,
    surfaceContainerHighest: cabecera,
    outline: borde,
    outlineVariant: altoContraste ? Colors.white : const Color(0xFF8A8A8A),
    secondaryContainer: tarjeta,
    onSecondaryContainer: texto,
    primaryContainer: tarjeta,
    onPrimaryContainer: texto,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: fondo,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );

  final textos = base.textTheme
      .copyWith(
        headlineSmall: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(fontSize: 18),
        bodyMedium: const TextStyle(fontSize: 16),
        labelLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      )
      .apply(bodyColor: texto, displayColor: texto);

  final formaBoton = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  );
  const tamMin = Size(48, 56);
  const relleno = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  return base.copyWith(
    textTheme: textos,
    focusColor: altoContraste ? Colors.white24 : Colors.black12,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primario,
        foregroundColor: sobrePrimario,
        minimumSize: tamMin,
        padding: relleno,
        textStyle: textos.labelLarge,
        shape: formaBoton.copyWith(side: BorderSide(color: borde, width: 2)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: tarjeta,
        foregroundColor: texto,
        minimumSize: tamMin,
        padding: relleno,
        textStyle: textos.labelLarge,
        side: BorderSide(color: borde, width: 2),
        shape: formaBoton,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        foregroundColor: texto,
        backgroundColor: tarjeta,
        side: BorderSide(color: borde, width: 2),
        shape: formaBoton,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tarjeta,
      hintStyle: TextStyle(color: textoSec, fontSize: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borde, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borde, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borde, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borde, width: 3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borde, width: 3),
      ),
      errorStyle: TextStyle(
        color: texto,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? sobrePrimario : textoSec,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? primario : tarjeta,
      ),
      trackOutlineColor: WidgetStatePropertyAll(borde),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cabecera,
      indicatorColor: tarjeta,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borde, width: 2.5),
      ),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: texto)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          color: texto,
          fontSize: 14,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.bold
              : FontWeight.w500,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borde, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: esquema.outlineVariant, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: texto,
      contentTextStyle: TextStyle(color: fondo, fontSize: 16),
    ),
  );
}
