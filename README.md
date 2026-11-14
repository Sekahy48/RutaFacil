# RutaFácil

Prototipo de app móvil accesible de autobús urbano (práctica de Accesibilidad, ULE).
8 pantallas navegables con **datos de ejemplo inventados**, sin tiempo real y con
horarios teóricos. Solo Android. Semana 4: sistema visual accesible, pruebas automáticas
de accesibilidad, verificación de contraste y capturas con simulaciones.

## Requisitos

- Flutter estable (probado con Flutter 3.47.3 / Dart 3.13.3).
- Android SDK y un emulador o un móvil Android.

## Ejecutar

```bash
flutter pub get
flutter run            # con un emulador abierto o un móvil conectado
```

## Generar el APK de depuración

```bash
flutter build apk --debug
```

El APK queda en `build/app/outputs/flutter-apk/app-debug.apk`.
Para instalarlo: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

## Pruebas

```bash
flutter analyze
flutter test           # test/accesibilidad_test.dart
```

`test/accesibilidad_test.dart` monta las 8 pantallas y estos estados: error de P1,
resultados de P1, aviso de P7, mapa con y sin conexión, y la barra inferior. Lo hace
en tema normal y en alto contraste, y pasa las guías `androidTapTargetGuideline`,
`labeledTapTargetGuideline` y `textContrastGuideline`. Además repite todo con el texto
al 200 % (`TextScaler.linear(2.0)`) y falla si algo desborda. Carga las fuentes Geist
reales para que las medidas de texto sean las del móvil. En las pruebas, P6 no consulta
la red: usa `PantallaMapa.conexionParaPruebas`.

## Sistema visual (semana 4)

- **Fuentes** (`assets/fonts/`, licencia SIL OFL en `LICENSE-Geist-OFL.txt`):
  Geist 400/500/600/700 y Geist Serif 400. Van empaquetadas con la app (no se usa
  `google_fonts` ni se descarga nada). Geist Serif solo se usa en los títulos de
  pantalla (28 sp). Escala: título 28/34, subtítulo 20/28 (600), cuerpo 16/24,
  botones y etiquetas 16/24 (600), pequeño 14/20. Todo en sp y sin límite de escala.
- **Tema**: todo está en `lib/ui/tema.dart`, como constantes con nombre (`kNormal…`,
  `kAlto…`, `kRadio` = 12 dp, `kBorde` = 2 dp, `kBordeEstado` = 3 dp, `kEspacio` = 8 dp…).
  Las pantallas leen la paleta con `context.paleta` y no usan colores sueltos.
  El foco se ve como un anillo de 3 dp por fuera del control, con un hueco del color
  del fondo (`FormaConFoco`).
- **Estados sin depender del color**:
  - error: borde de 3 dp, ⚠, «Error:» y cómo corregirlo;
  - éxito: «✓»;
  - opción elegida: relleno y «✓»;
  - pestaña activa: relleno y negrita;
  - aviso: ⚠, «AVISO», borde de 3 dp y vibración;
  - desactivado: atenuado, y TalkBack añade «no disponible».

  Las líneas se distinguen con las etiquetas neutras «L1»…«L4».
- **Barra inferior**: crece con el texto. Si las cinco pestañas no caben en una fila,
  se reparten en 3 + 2 (o menos por fila).
- **Mapa en alto contraste**: se usan las mismas teselas de OpenStreetMap, oscurecidas
  en el propio móvil con un `ColorFiltered`. La matriz baja la saturación, invierte los
  colores y ajusta el brillo; sus constantes `kMapaOscuro…` están en `tema.dart`.
  Se eligió frente a cambiar a otro proveedor de teselas oscuras por tres motivos:
  CARTO, el proveedor gratuito de teselas oscuras más común, pide ahora clave de API
  y registro (según su repositorio oficial basemap-styles, consultado en noviembre de 2026); así se mantienen el mismo
  proveedor, la misma atribución y el mismo comportamiento sin conexión; y no añade
  dependencias. Contraste aproximado medido sobre las capturas:
  - alto contraste: el pin claro sobre el mapa oscuro, entre 6,8:1 (zonas más claras
    del mapa, percentil 95) y 17:1;
  - tema normal: el borde oscuro del pin sobre el mapa, ≥ 8:1.

  La atribución de OSM va en una franja propia bajo el mapa, así que no tapa pines.

## Scripts (`docs/scripts/`)

- `python docs/scripts/contrastes.py`: sin dependencias. Lee los hex de `tema.dart`,
  calcula el contraste WCAG 2.2 de 22 pares de uso (16 del tema normal y 6 del de alto
  contraste) y escribe `docs/contrastes_app.csv`. Avisa si algún hex no coincide con la
  especificación o si algún par da FAIL; en ese caso termina con código 1.
- `python docs/scripts/simular.py`: necesita `pip install pillow numpy`. A partir de
  `docs/capturas_s4/normal/` genera `grises/` (luminancia WCAG), `protanopia/` y
  `deuteranopia/` (matrices de Machado et al. 2009, severidad 1,0, en RGB lineal).
  **Son simulaciones aproximadas.**

## Estructura

```
lib/
  main.dart                 Tema y arranque
  estado.dart               Estado en memoria (ajustes, pestaña, precarga P5 → P1)
  data/datos_mock.dart      Paradas, líneas, horarios de ejemplo y hora de referencia
  data/planificador.dart    Trayectos directos o con 1 trasbordo (máx. 3)
  ui/tema.dart              Paletas, tipografía, medidas y anillo de foco
  ui/comunes.dart           Cabecera, filas, cajas de error, etiquetas L1…L4, campos, foco
  ui/armazon.dart           Barra inferior: Buscar · Líneas · Paradas · Mapa · Ajustes
  ui/pantallas/p1…p8        Las 8 pantallas
docs/
  Prompt_Code_RutaFacil.md  Especificación
  wireframes/               Wireframes de referencia
  capturas/                 Capturas de la semana 3
  capturas_s4/              Capturas de la semana 4: normal/, alto_contraste/, texto_200/,
                            grises/, protanopia/, deuteranopia/
  scripts/                  contrastes.py y simular.py
  contrastes_app.csv        Resultado de contrastes.py
assets/fonts/               Geist y Geist Serif (OFL)
test/accesibilidad_test.dart
```

## Notas

- **Hora de referencia**: fija a las 08:30 para que las pruebas se puedan repetir.
  Se cambia en `lib/data/datos_mock.dart` (`kUsarHoraFija = false` usa la hora del móvil).
- **Mapa**: teselas de OpenStreetMap (oscurecidas en alto contraste); necesita conexión. Sin conexión se muestra un aviso
  y un botón a la lista de paradas. El resto de la app funciona sin conexión.
- **Ubicación**: simulada. Se muestra el diálogo explicativo, pero no se pide el permiso
  del sistema ni se usa el GPS.
- Los ajustes no se guardan al cerrar la app (se hará en la siguiente iteración).
