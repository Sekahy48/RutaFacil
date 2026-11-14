# Prompt para Claude Code — RutaFácil, semana 4: sistema visual accesible

Contexto: el repo ya tiene la app Flutter de la semana 3 (8 pantallas, datos de ejemplo, tema en grises, tema de alto contraste, 0 avisos de `flutter analyze`). Lee `docs/Prompt_Code_RutaFacil.md` (especificación de pantallas y datos, sigue vigente) y mira `docs/wireframes/`. Esta iteración NO añade funciones nuevas: solo **sistema visual, correcciones de accesibilidad pendientes, pruebas y evidencias**. Trabaja en la raíz del repo. Commits pequeños en español. **No hagas push** (lo hace el usuario).

## 0. Antes de empezar
- `git status` y `git log -3`. Si hay cambios sin commitear que no son tuyos, dímelo y no los toques.
- Las fuentes están en `assets/fonts/` (las copia el usuario desde el zip `Geist_fuentes.zip`): `Geist-Regular.ttf`, `Geist-Medium.ttf`, `Geist-SemiBold.ttf`, `Geist-Bold.ttf`, `GeistSerif-Regular.ttf` y `LICENSE-Geist-OFL.txt`. Si faltan, para y dímelo. **No uses `google_fonts` ni descargues nada en ejecución**: la app debe funcionar sin conexión.

## 1. Tipografía
- Declara en `pubspec.yaml` la familia `Geist` (pesos 400, 500, 600, 700) y `GeistSerif` (400).
- **Geist Serif solo para títulos de pantalla (28 sp)**: es una serif de display de alto contraste y trazo fino, de un solo peso, y no es legible en tamaños pequeños. Todo lo demás en Geist.
- Escala (todo en sp, escalando con el texto del sistema, sin límites): título 28/34 GeistSerif 400; subtítulo 20/28 Geist 600; cuerpo 16/24 Geist 400; botones y etiquetas 16/24 Geist 600; texto pequeño 14/20 Geist 400 (**nada por debajo de 14 sp**).
- Comprueba que los pesos 500/600/700 se ven distintos en el emulador (que no haya negrita sintética).
- Si Geist Serif no se ve bien o no carga, usa Geist 600 para los títulos y avísame.

## 2. Tema (todo en `lib/ui/tema.dart`, como constantes con nombre; sin colores sueltos en las pantallas)
Tema normal (hex exactos, ya medidos; no los cambies sin avisar):
- fondo `#F1F1EE`; superficie `#F8F8F6` (no uses `#FFFFFF` en ningún sitio); texto `#1B1F23`; texto secundario `#444B52`
- acento `#2C5F6F` (texto sobre acento `#F8F8F6`); borde `#6A7178`; foco `#1A4FB5`
- error `#A12626`; éxito `#1F6B36`; aviso fondo `#FFF1CC` con borde `#8A5A00`
- pestaña inactiva fondo `#E9E9E4`; mapa claro `#E8E8E4`
Tema de alto contraste (misma estructura): fondo `#121214`; texto `#F2F2F2`; texto secundario `#D4D4D4`; acento/botones/bordes/foco `#E8D27F` (texto sobre acento `#121214`); no uses `#000000` ni `#FFFFFF`; error `#FF9E9E`; éxito `#8DF0A0`.
Reglas:
- 8 dp como base de espaciado; separación ≥ 8 dp entre controles contiguos; ≥ 24 dp entre «Salir» / «Terminar trayecto» y controles vecinos.
- Esquinas redondeadas de **12 dp** en botones, tarjetas y campos (constante `kRadio` en `tema.dart`); los pines del mapa y las opciones 1/2/3 pueden usar el mismo radio. El redondeo no debe reducir el área táctil (≥ 48×48 dp) ni el borde visible. Desactiva cualquier forma de píldora por defecto de Material.
- Bordes de botones y campos 2 dp; foco visible 3 dp con el color de foco.
- Botón principal alto 56 dp, ancho completo; secundario ≥ 48 dp con borde de acento. Campo de texto ≥ 56 dp con **etiqueta visible encima** (no solo hint).
- Estados **sin depender del color**: error = borde 3 dp + icono ⚠ + prefijo «Error:» + cómo corregirlo; éxito = «✓» + texto; opción elegida = relleno + «✓» (las no elegidas solo borde); pestaña activa = relleno + negrita; aviso = icono ⚠ + texto «AVISO» + borde 3 dp + vibración; desactivado = atenuado + etiqueta semántica «no disponible».
- Líneas identificadas con etiqueta de texto «L1»…«L4» en neutro (nunca por color).
- Pin del mapa: ≥ 48 dp, fondo `#F8F8F6`, borde 2 dp, nombre dentro.
- Quita cualquier color que no esté en esta lista.

## 2b. Mapa en el tema de alto contraste
En el tema normal el mapa sigue claro (teselas OSM de `tile.openstreetmap.org`). En el tema de alto contraste el mapa debe verse oscuro. **Sopesa dos opciones y elige una**, justificándolo en el informe:
- **A. Oscurecer en casa:** `ColorFiltered` con matriz de color (invertir, bajar saturación y ajustar brillo) sobre `TileLayer`, solo en alto contraste. Sigue usando OSM; la política de OSM no menciona restilizar teselas raster, pero exige atribución visible, `userAgentPackageName` propio y no usar teselas sin conexión ni precargarlas.
- **B. Otro proveedor de mapa oscuro** (teselas raster oscuras públicas). Antes de elegirlo, comprueba sus condiciones de uso (uso no comercial, atribución obligatoria, límites, necesidad de clave o registro) y no uses ninguno de pago ni que requiera clave sin avisarme. Si lo usas, muestra su atribución además de la de OpenStreetMap, y que el fallo sin conexión siga igual (mensaje + lista).
Criterios de decisión: legibilidad de calles y etiquetas frente a los pines (pin ≥ 3:1 contra el fondo del mapa), condiciones de uso, simplicidad y que no cambie el comportamiento sin conexión. Haz capturas de las dos opciones si puedes y mide el contraste pin/mapa sobre ellas (aproximado, indícalo). Deja en `README` y en el informe qué has elegido y por qué.

## 3. Correcciones pendientes de la semana 3
1. **Texto al 200 %**: quita el límite de 1,3× de la barra inferior y de los pines. La barra debe seguir usable al 200 % (por ejemplo, etiquetas en dos líneas y altura que crece, o disposición alternativa). Los pines crecen con el texto. Sin recortes ni solapes.
2. **Iconos y flechas del mapa**: etiqueta semántica inequívoca («Desplazar mapa a la izquierda», «Acercar», «Alejar»…) y tooltip. Ningún icono solo sin nombre.
3. Mensajes de error de P1 y P4: qué ha pasado y cómo corregirlo.
No toques nada más del comportamiento.

## 4. Pruebas automáticas de accesibilidad (`test/accesibilidad_test.dart`)
Con `flutter_test` (sin paquetes nuevos), para cada una de las 8 pantallas (P7 con aviso incluido) y en tema normal y de alto contraste:
- `meetsGuideline(androidTapTargetGuideline)`, `meetsGuideline(labeledTapTargetGuideline)` y `meetsGuideline(textContrastGuideline)`.
- Una prueba de texto al 200 % (`textScaler: TextScaler.linear(2.0)`) que verifique que no hay `overflow` en ninguna pantalla.
Los fallos que salgan: arréglalos si son de la app; si es un falso positivo (p. ej. mapa con teselas), explícalo en el informe y desactiva solo ese caso con comentario.

## 5. Verificación de contraste (`docs/scripts/contrastes.py`)
Script de Python (sin dependencias) que lea los hex de `tema.dart`, calcule el contraste WCAG 2.2 de estos pares y escriba `docs/contrastes_app.csv` con columnas `id,uso,primer_plano,fondo,ratio,minimo,resultado`:
texto/fondo (4,5), texto/superficie (4,5), texto secundario/fondo (4,5), texto secundario/superficie (4,5), superficie/acento (4,5), acento/superficie (4,5), error/superficie (4,5), éxito/superficie (4,5), texto/aviso fondo (4,5), superficie/acento pestaña activa (4,5), texto secundario/pestaña inactiva (4,5), borde/fondo (3), borde/superficie (3), foco/fondo (3), borde aviso/fondo aviso (3), acento/superficie selección (3), y los 6 pares del tema de alto contraste. Si algún valor del tema difiere de los hex de arriba, o algún par da FAIL, **avísame** en el informe.

## 6. Capturas y simulaciones (`docs/capturas_s4/`)
- Compila y ejecuta en el emulador. Capturas de las 8 pantallas y estados (error de P1, aviso de P7, mapa sin conexión) en tema normal → `normal/`; en alto contraste → `alto_contraste/`; con texto al 200 % (P1, P4, P6, P7, P8) → `texto_200/`; el mapa oscuro (opción elegida y, si las has probado, la otra) → `alto_contraste/`.
- Script `docs/scripts/simular.py` (Python con PIL y numpy): a partir de las capturas normales genera `grises/`, `protanopia/` y `deuteranopia/` (matrices de Machado et al. 2009, severidad 1,0, aplicadas en RGB lineal; para grises, luminancia WCAG). Indica en el informe que son simulaciones aproximadas.
- Nombres de archivo coherentes (`P1_resultados.png`, etc.).

## 7. Entrega
- `flutter analyze` 0 avisos; `flutter test` verde (o fallos explicados); APK debug nuevo (`flutter build apk --debug`) y su ruta.
- README actualizado (fuentes, tema, tests, scripts).
- Informe final corto: qué cambió, resultados de los tests y de `contrastes.csv`, qué **no** has podido verificar (TalkBack, vibración, contraste medido sobre capturas reales), decisiones que has tomado y dudas. No afirmes nada que no hayas ejecutado.
