# Prompt para sesión de Claude Code — Prototipo Flutter «RutaFácil» (iteración 1: solo pantallas)

Contexto: práctica de Accesibilidad (ULE). App móvil accesible de autobús urbano, zona de prueba tipo León, **datos de ejemplo inventados, sin tiempo real, horarios teóricos**. Esta iteración: **solo las 8 pantallas navegables con datos mock**. NO hacer: registro de pruebas/CSV, persistencia de ajustes, sistema de diseño visual, tests automáticos, backend. (Se hará en la siguiente iteración.)

## Tarea
0. Trabaja en la raíz del repo actual (`rutafacil/`, ya con `git init`; contiene `docs/`). No toques `docs/` salvo para añadir capturas.
1. `flutter create .` en la raíz (solo Android: `--platforms=android`). Dart null-safe, solo paquetes: `flutter_map`, `latlong2`. Nada más salvo necesidad justificada.
2. Implementar las 8 pantallas y navegación. Estado en memoria (setState/ValueNotifier simple, sin paquetes de estado).
3. Haz commits pequeños (uno por pantalla o hito, mensaje claro en español). Ejecutar `flutter analyze` (0 avisos), correr en emulador Android, recorrer las 3 rutas críticas, hacer capturas de cada pantalla y generar APK debug (`flutter build apk --debug`).
4. Informar: problemas, decisiones tomadas, ruta del APK y capturas. No inventar resultados que no hayas ejecutado.

## Requisitos transversales de accesibilidad (obligatorios)
- Tema neutro en escala de grises, texto negro sobre blanco/gris claro, contraste ≥ 4,5:1. El estado nunca solo por color (usar texto/icono: "✓", etc.).
- Todo control táctil ≥ 48×48 dp, con separación. Toda acción con un solo toque; nada exige arrastrar, mantener pulsado ni gestos complejos (el mapa admite gestos pero siempre hay botones equivalentes).
- `Semantics`/labels descriptivos en todo control, pines del mapa incluidos (p. ej. "Parada Catedral, abrir detalle"). Orden de foco lógico. Títulos con `Semantics(header: true)`.
- Debe tolerar escala de texto hasta 200 % sin recortes ni solapes (scroll vertical donde haga falta; `Text` sin `maxLines` fijos).
- Idioma: español. Lenguaje claro y frases cortas.
- Barra de navegación inferior (NavigationBar) con: **Buscar · Líneas · Paradas · Mapa · Ajustes**. Pantalla inicial: **Buscar ruta**. La barra no aparece en Seguimiento.

## Datos mock
Paradas (id → nombre): estacion "Estación", guzman "Guzmán", catedral "Catedral", sanmarcos "San Marcos", universidad "Universidad", hospital "Hospital", quevedo "Quevedo". Coordenadas: inventa unas coherentes en una zona de ~2 km del centro de León (aprox. 42.60, -5.57), con las posiciones relativas del wireframe P6 (Estación arriba-izquierda, Hospital abajo-derecha). Son de ejemplo.
Líneas (offsets en minutos desde salida; primera salida / frecuencia):
- L1: Estación, Guzmán, Catedral, San Marcos, Universidad, Hospital — offsets [0,4,7,11,16,20] — 08:05 cada 15 min
- L2: Estación, Guzmán, San Marcos, Hospital — [0,6,12,22] — 08:10 cada 20 min
- L3: Estación, Guzmán, Catedral, Universidad — [0,5,9,17] — 08:03 cada 20 min
- L4: Quevedo, Universidad, Hospital — [0,8,12] — 08:20 cada 30 min
Servicio de 08:00 a ~22:00. Ruta = directa o con 1 trasbordo, hasta 3 opciones, ordenadas por duración. Hora de referencia = hora actual del dispositivo (o fija 08:30 si es más simple, configurable en una constante). Referencia de comportamiento: wireframes en `docs/wireframes/` (P1a…P8 en PNG/SVG, nav; léelos como referencia visual).

## Pantallas
- **P1 Buscar ruta** (inicial). Campos Origen y Destino (selección entre paradas de la zona, con texto "Escribe o elige una parada" y sugerencias en lista, sin autocompletado complejo), botón «Buscar trayecto». Resultado: hasta 3 tarjetas «Opción n · Línea X · N min · sin trasbordo» (o con trasbordo en parada Y) con botón «Elegir». Error si origen = destino: «Error: origen y destino son la misma parada. Cambia el destino.» (con foco/anuncio accesible). «Elegir» → P7.
- **P2 Líneas**: lista de L1–L4 con recorrido resumido ("Estación – Hospital"); toque → P3.
- **P3 Detalle de línea**: paradas en orden, cada una con «Próximos: hh:mm · hh:mm · hh:mm»; toque en parada → P5. Aviso «Horarios teóricos (sin tiempo real)».
- **P4 Paradas**: campo de búsqueda + lista de todas las paradas (equivalente accesible del mapa; funciona sin conexión); toque → P5.
- **P5 Detalle de parada**: nombre, líneas que pasan, próximos horarios teóricos, botones «Como origen» y «Como destino» (precargan P1 y llevan a ella), texto «Horarios teóricos (sin tiempo real)».
- **P6 Mapa** (interactivo): `flutter_map` con teselas OSM (atribución visible «© OpenStreetMap contributors»; User-Agent propio vía `userAgentPackageName`), limitado a la zona de prueba (`cameraConstraint`/bounds). Pines = botones de ≥ 48 dp con el nombre de la parada → P5. Botones +, −, ◀ ▲ ▼ ▶ para zoom/desplazar (equivalentes a los gestos). Botón «Ver como lista» → P4. Botón «Mostrar mi ubicación»: diálogo previo de explicación («La ubicación se usa solo en tu dispositivo y no se guarda ni se envía») con «Permitir» / «Ahora no»; solo entonces pedir permiso (puedes usar `geolocator` solo si hace falta; si complica, deja el diálogo y un marcador simulado y anótalo). Sin conexión (o fallo de teselas): mensaje «El mapa necesita conexión. Usa la lista de paradas.» con botón a P4; la app sigue funcionando. Añadir permiso INTERNET en el manifest.
- **P7 Seguimiento** (sin barra inferior): «Te bajas en: <parada>», «Faltan N paradas», «Parada actual: X», «Paso k de n», botones «Paso anterior» / «Paso siguiente» (simulan avance), «He pasado una parada». Cuando faltan ≤ antelación (por defecto 2): tarjeta «AVISO · Prepárate: te bajas en N paradas», con vibración (`HapticFeedback.heavyImpact`) y mensaje visible (sonido opcional según ajuste, puede ser `SystemSound`). Al llegar: «Has llegado a tu parada» + «Terminar trayecto» (vuelve a P1). Botón «Salir» con diálogo de confirmación («¿Salir del seguimiento?» Sí/No).
- **P8 Ajustes**: «Tema de alto contraste» (conmutador; negro/blanco), «Avisar con antelación» 1 / 2 / 3 paradas (seleccionado marcado con «✓» además del estilo), «Sonido del aviso» (conmutador). Texto fijo: «La vibración y el mensaje del aviso siempre están activados.» Estado en memoria.

## Tres recorridos críticos a poder completar (C1–C3)
C1: encontrar cómo ir de Estación a Hospital (P1→opciones→Elegir→P7). C2: mirar horarios de una parada (P4/P6→P5). C3: cambiar la antelación del aviso (P8) y comprobarlo en P7.

## Entrega
- Código en el repo con README breve (cómo ejecutar y generar APK).
- `flutter analyze` sin avisos; capturas de las 8 pantallas (incluyendo error de P1 y mapa sin conexión) en `docs/capturas/`.
- Lista de limitaciones y dudas (p. ej. si TalkBack no se pudo probar). No afirmar que cumple accesibilidad sin haberlo comprobado; señalar lo verificado (tamaños, escala de texto) y lo no verificado.
