// P6 · Mapa interactivo de la zona de prueba (teselas OpenStreetMap).
// Los gestos funcionan, pero todo se puede hacer también con botones.
//
// En el tema de alto contraste las mismas teselas de OSM se oscurecen en el
// propio dispositivo con un ColorFiltered (opción A de la semana 4): mismo
// proveedor, misma atribución y mismo comportamiento sin conexión.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/paradas_lineas.dart';
import '../../estado.dart';
import '../comunes.dart';
import '../tema.dart';
import 'p5_detalle_parada.dart';

/// Zona de prueba: la cámara no puede salir de aquí.
final _limites = LatLngBounds(
  const LatLng(42.5860, -5.5900),
  const LatLng(42.6140, -5.5500),
);

/// Opciones del mapa, creadas una sola vez: si se recrean en cada build,
/// flutter_map vuelve a validar la cámara contra el límite y falla.
final _opciones = MapOptions(
  initialCenter: const LatLng(42.6003, -5.5693),
  initialZoom: 14.2,
  minZoom: 13,
  maxZoom: 18,
  cameraConstraint: CameraConstraint.containCenter(bounds: _limites),
  interactionOptions: const InteractionOptions(
    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
  ),
  // El fondo lo pone el ColoredBox que envuelve al mapa (color del tema).
  backgroundColor: Colors.transparent,
);

/// Posición SIMULADA del usuario (no se usa el GPS en este prototipo).
const _ubicacionSimulada = LatLng(42.6008, -5.5688);

/// Matriz de color que oscurece las teselas en alto contraste: baja la
/// saturación, invierte y ajusta el brillo. Resultado: fondo casi negro,
/// calles oscuras y rótulos claros.
List<double> matrizMapaOscuro({
  double saturacion = kMapaOscuroSaturacion,
  double escala = kMapaOscuroEscala,
  double desplazamiento = kMapaOscuroDesplazamiento,
}) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final g = 1 - saturacion;
  final d = [
    [lr * g + saturacion, lg * g, lb * g],
    [lr * g, lg * g + saturacion, lb * g],
    [lr * g, lg * g, lb * g + saturacion],
  ];
  return [
    for (final fila in d) ...[
      -escala * fila[0],
      -escala * fila[1],
      -escala * fila[2],
      0,
      escala * 255 + desplazamiento,
    ],
    0, 0, 0, 1, 0, //
  ];
}

/// Estilo del nombre dentro del pin (el color lo pone la paleta del tema).
const _estiloPin = kEstiloEtiqueta;

/// Tamaño del pin: crece con el texto (sin límite de escala), ≥ 48 dp.
Size _tamPin(
  String texto,
  TextScaler escala, {
  double extra = 0,
  double grosor = kBorde,
}) {
  final tp = TextPainter(
    text: TextSpan(text: texto, style: _estiloPin),
    textDirection: TextDirection.ltr,
    textScaler: escala,
    maxLines: 1,
  )..layout();
  final tam = Size(
    math.max(kTactilMinimo, tp.width + extra + 2 * 12 + 2 * grosor + 2),
    math.max(kTactilMinimo, tp.height + 2 * kEspacio + 2 * grosor),
  );
  tp.dispose();
  return tam;
}

enum _Conexion { comprobando, ok, sinConexion }

class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key});

  /// Solo para pruebas: si no es null, sustituye la comprobación de red
  /// (true = hay conexión, false = sin conexión).
  @visibleForTesting
  static bool? conexionParaPruebas;

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  final _mapa = MapController();
  var _conexion = _Conexion.comprobando;
  var _erroresTesela = 0;
  var _mostrarUbicacion = false;

  @override
  void initState() {
    super.initState();
    estado.pestana.addListener(_alCambiarPestana);
    _comprobarConexion();
  }

  @override
  void dispose() {
    estado.pestana.removeListener(_alCambiarPestana);
    _mapa.dispose();
    super.dispose();
  }

  void _alCambiarPestana() {
    if (estado.pestana.value == Pestana.mapa) _comprobarConexion();
  }

  Future<void> _comprobarConexion() async {
    var ok = false;
    final simulada = PantallaMapa.conexionParaPruebas;
    if (simulada != null) {
      ok = simulada;
    } else {
      ok = await _hayRed();
    }
    if (!mounted) return;
    setState(() {
      _erroresTesela = 0;
      _conexion = ok ? _Conexion.ok : _Conexion.sinConexion;
    });
  }

  Future<bool> _hayRed() async {
    var ok = false;
    try {
      final r = await InternetAddress.lookup('tile.openstreetmap.org')
          .timeout(const Duration(seconds: 4));
      ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } on Exception {
      ok = false;
    }
    return ok;
  }

  void _errorTesela(TileImage tile, Object error, StackTrace? st) {
    // Varias teselas fallidas seguidas = sin conexión o servidor caído.
    _erroresTesela++;
    if (_erroresTesela >= 3 && _conexion != _Conexion.sinConexion && mounted) {
      setState(() => _conexion = _Conexion.sinConexion);
    }
  }

  void _zoom(double delta) {
    final c = _mapa.camera;
    _mapa.move(c.center, c.zoom + delta);
  }

  /// Desplaza el mapa un 30 % de lo visible. dx/dy en −1, 0, 1.
  void _mover(int dx, int dy) {
    final c = _mapa.camera;
    final b = c.visibleBounds;
    final dLat = (b.north - b.south) * 0.3 * dy;
    final dLng = (b.east - b.west) * 0.3 * dx;
    final ok = _mapa.move(
      LatLng(c.center.latitude + dLat, c.center.longitude + dLng),
      c.zoom,
    );
    if (!ok) anunciar(context, 'Has llegado al borde de la zona de prueba.');
  }

  void _abrirParada(Parada p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaDetalleParada(parada: p, volverA: 'Mapa'),
      ),
    );
  }

  Future<void> _pedirUbicacion() async {
    final permitir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: const Text('Mostrar mi ubicación'),
        ),
        content: const Text(
          'La ubicación se usa solo en tu dispositivo y no se guarda ni se '
          'envía.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (permitir == true) {
      // Prototipo: no se pide el permiso del sistema ni se usa el GPS;
      // se muestra una posición simulada.
      setState(() => _mostrarUbicacion = true);
      if (_conexion == _Conexion.ok) _mapa.move(_ubicacionSimulada, 16);
      anunciar(
        context,
        'Ubicación simulada mostrada en el mapa, cerca de Catedral.',
      );
    } else {
      anunciar(context, 'No se usará tu ubicación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      titulo: 'Mapa de la zona',
      cuerpo: switch (_conexion) {
        _Conexion.comprobando => Center(
          child: Semantics(
            liveRegion: true,
            label: 'Cargando mapa',
            child: const CircularProgressIndicator(),
          ),
        ),
        _Conexion.sinConexion => _SinConexion(
          onReintentar: () {
            setState(() => _conexion = _Conexion.comprobando);
            _comprobarConexion();
          },
        ),
        _Conexion.ok => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _construirMapa()),
            // Atribución en su propia franja: nunca tapa un pin.
            const _Atribucion(),
            // Con texto grande, el mapa se queda más alto y los controles
            // (que se pueden desplazar) ocupan menos.
            Flexible(
              flex: MediaQuery.textScalerOf(context).scale(10) > 15 ? 1 : 2,
              child: _construirControles(),
            ),
          ],
        ),
      },
    );
  }

  Widget _construirMapa() {
    final p = context.paleta;
    final escala = MediaQuery.textScalerOf(context);
    Widget teselas = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'es.unileon.rutafacil',
      errorTileCallback: _errorTesela,
    );
    if (p.altoContraste) {
      teselas = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrizMapaOscuro()),
        child: teselas,
      );
    }
    final tamUbicacion = _tamPin('Tú (simulado)', escala, extra: 24);
    return Semantics(
      container: true,
      label:
          'Mapa de la zona con ${kParadas.length} paradas. '
          'Toca una parada para ver sus horarios.',
      child: ColoredBox(
        color: p.mapa,
        child: FlutterMap(
          mapController: _mapa,
          options: _opciones,
          children: [
            teselas,
            MarkerLayer(
              markers: [
                if (_mostrarUbicacion)
                  Marker(
                    point: _ubicacionSimulada,
                    width: tamUbicacion.width,
                    height: tamUbicacion.height,
                    child: const _MarcaUbicacion(),
                  ),
                for (final parada in kParadas)
                  Marker(
                    point: parada.posicion,
                    width: _tamPin(
                      parada.nombre,
                      escala,
                      grosor: p.pinGrosor,
                    ).width,
                    height: _tamPin(
                      parada.nombre,
                      escala,
                      grosor: p.pinGrosor,
                    ).height,
                    child: _Pin(
                      parada: parada,
                      onTap: () => _abrirParada(parada),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirControles() {
    final p = context.paleta;
    // Cada icono lleva un nombre inequívoco: tooltip (al mantener pulsado)
    // y la misma etiqueta para TalkBack.
    Widget boton(IconData icono, String etiqueta, VoidCallback onTap) =>
        IconButton(
          onPressed: onTap,
          tooltip: etiqueta,
          icon: Icon(icono, size: 28, semanticLabel: etiqueta),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.fondo,
        border: Border(
          top: BorderSide(color: p.borde, width: kBorde),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: kEspacio,
              runSpacing: kEspacio,
              children: [
                boton(Icons.add, 'Acercar', () => _zoom(1)),
                boton(Icons.remove, 'Alejar', () => _zoom(-1)),
                boton(
                  Icons.arrow_back,
                  'Desplazar mapa a la izquierda',
                  () => _mover(-1, 0),
                ),
                boton(
                  Icons.arrow_upward,
                  'Desplazar mapa hacia arriba',
                  () => _mover(0, 1),
                ),
                boton(
                  Icons.arrow_downward,
                  'Desplazar mapa hacia abajo',
                  () => _mover(0, -1),
                ),
                boton(
                  Icons.arrow_forward,
                  'Desplazar mapa a la derecha',
                  () => _mover(1, 0),
                ),
              ],
            ),
            const SizedBox(height: 2 * kEspacio),
            FilledButton(
              onPressed: () => estado.irA(Pestana.paradas),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kAltoBotonPrincipal),
              ),
              child: const Text('Ver como lista'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _pedirUbicacion,
              child: const Text('Mostrar mi ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pin de parada: botón ≥ 48 dp con el nombre dentro. Colores y grosor de
/// borde salen de la paleta del tema (normal: claro con borde oscuro de 2 dp;
/// alto contraste: fondo AC, texto AC y borde de acento de 3 dp). El foco es
/// el anillo de 3 dp de [Tocable]. Crece con el texto.
class _Pin extends StatelessWidget {
  const _Pin({required this.parada, required this.onTap});

  final Parada parada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      button: true,
      label: 'Parada ${parada.nombre}, abrir detalle',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: p.pinFondo,
        shape: RoundedRectangleBorder(
          borderRadius: kRadioBorde,
          side: BorderSide(color: p.pinBorde, width: p.pinGrosor),
        ),
        child: Tocable(
          onTap: onTap,
          child: Center(
            child: Text(
              parada.nombre,
              maxLines: 1,
              style: _estiloPin.copyWith(color: p.pinTexto),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarcaUbicacion extends StatelessWidget {
  const _MarcaUbicacion();

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      label: 'Tu ubicación (simulada)',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: p.acento,
          borderRadius: kRadioBorde,
          border: Border.all(color: p.sobreAcento, width: kBorde),
        ),
        padding: const EdgeInsets.symmetric(horizontal: kEspacio),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.my_location, color: p.sobreAcento, size: 20),
            const SizedBox(width: 4),
            Text(
              'Tú (simulado)',
              maxLines: 1,
              style: kEstiloEtiqueta.copyWith(color: p.sobreAcento),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atribución siempre visible (requisito de OpenStreetMap).
class _Atribucion extends StatelessWidget {
  const _Atribucion();

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      color: p.superficie,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: kEspacio, vertical: 2),
      child: Text(
        '© OpenStreetMap contributors',
        style: kEstiloCuerpo.copyWith(color: p.texto),
      ),
    );
  }
}

class _SinConexion extends StatelessWidget {
  const _SinConexion({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final p = context.paleta;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Semantics(
          liveRegion: true,
          child: Caja(
            grosor: kBordeEstado,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.cloud_off, size: 32, color: p.texto),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El mapa necesita conexión. Usa la lista de paradas.',
                    style: tt.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => estado.irA(Pestana.paradas),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(kAltoBotonPrincipal),
          ),
          child: const Text('Ver lista de paradas'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onReintentar,
          child: const Text('Reintentar'),
        ),
        const SizedBox(height: 20),
        Text('El resto de la app funciona sin conexión.', style: tt.bodyLarge),
      ],
    );
  }
}
