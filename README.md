# RutaFácil

Prototipo de app móvil accesible de autobús urbano (práctica de Accesibilidad, ULE).
Iteración 1: 8 pantallas navegables con **datos de ejemplo inventados**, sin tiempo real
y con horarios teóricos. Solo Android.

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

## Estructura

```
lib/
  main.dart                 Tema y arranque
  estado.dart               Estado en memoria (ajustes, pestaña, precarga P5 → P1)
  data/datos_mock.dart      Paradas, líneas, horarios de ejemplo y hora de referencia
  data/planificador.dart    Trayectos directos o con 1 trasbordo (máx. 3)
  ui/tema.dart              Tema gris neutro y tema de alto contraste
  ui/comunes.dart           Cabecera, filas de lista, cajas, anuncios para TalkBack
  ui/armazon.dart           Barra inferior: Buscar · Líneas · Paradas · Mapa · Ajustes
  ui/pantallas/p1…p8        Las 8 pantallas
docs/
  Prompt_Code_RutaFacil.md  Especificación
  wireframes/               Wireframes de referencia
  capturas/                 Capturas tomadas en el emulador
```

## Notas

- **Hora de referencia**: fija a las 08:30 para que las pruebas se puedan repetir.
  Se cambia en `lib/data/datos_mock.dart` (`kUsarHoraFija = false` usa la hora del móvil).
- **Mapa**: teselas de OpenStreetMap; necesita conexión. Sin conexión se muestra un aviso
  y un botón a la lista de paradas. El resto de la app funciona sin conexión.
- **Ubicación**: simulada. Se muestra el diálogo explicativo, pero no se pide el permiso
  del sistema ni se usa el GPS.
- Los ajustes no se guardan al cerrar la app (se hará en la siguiente iteración).
