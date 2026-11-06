// P6 · Mapa interactivo de la zona de prueba (teselas OpenStreetMap).
// Los gestos funcionan, pero todo se puede hacer también con botones.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/datos_mock.dart';
import '../../estado.dart';
import '../comunes.dart';
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
);

/// Posición SIMULADA del usuario (no se usa el GPS en este prototipo).
const _ubicacionSimulada = LatLng(42.6008, -5.5688);

enum _Conexion { comprobando, ok, sinConexion }

class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key});

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
    try {
      final r = await InternetAddress.lookup('tile.openstreetmap.org')
          .timeout(const Duration(seconds: 4));
      ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } on Exception {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _erroresTesela = 0;
      _conexion = ok ? _Conexion.ok : _Conexion.sinConexion;
    });
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
            Flexible(flex: 2, child: _construirControles()),
          ],
        ),
      },
    );
  }

  Widget _construirMapa() {
    return Semantics(
      container: true,
      label:
          'Mapa de la zona con ${kParadas.length} paradas. '
          'Toca una parada para ver sus horarios.',
      child: FlutterMap(
        mapController: _mapa,
        options: _opciones,
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'es.unileon.rutafacil',
            errorTileCallback: _errorTesela,
          ),
          MarkerLayer(
            markers: [
              if (_mostrarUbicacion)
                const Marker(
                  point: _ubicacionSimulada,
                  width: 120,
                  height: 56,
                  child: _MarcaUbicacion(),
                ),
              for (final p in kParadas)
                Marker(
                  point: p.posicion,
                  width: 36.0 + p.nombre.length * 11,
                  height: 52,
                  child: _Pin(parada: p, onTap: () => _abrirParada(p)),
                ),
            ],
          ),
          const _Atribucion(),
        ],
      ),
    );
  }

  Widget _construirControles() {
    final esquema = Theme.of(context).colorScheme;
    Widget boton(IconData icono, String etiqueta, VoidCallback onTap) =>
        IconButton(
          onPressed: onTap,
          tooltip: etiqueta,
          icon: Icon(icono, size: 28),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: esquema.surface,
        border: Border(top: BorderSide(color: esquema.outline, width: 1.5)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                boton(Icons.add, 'Acercar', () => _zoom(1)),
                boton(Icons.remove, 'Alejar', () => _zoom(-1)),
                boton(
                  Icons.arrow_back,
                  'Mover el mapa a la izquierda',
                  () => _mover(-1, 0),
                ),
                boton(
                  Icons.arrow_upward,
                  'Mover el mapa hacia arriba',
                  () => _mover(0, 1),
                ),
                boton(
                  Icons.arrow_downward,
                  'Mover el mapa hacia abajo',
                  () => _mover(0, -1),
                ),
                boton(
                  Icons.arrow_forward,
                  'Mover el mapa a la derecha',
                  () => _mover(1, 0),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => estado.irA(Pestana.paradas),
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

/// Pin de parada: botón ≥ 48 dp con el nombre.
class _Pin extends StatelessWidget {
  const _Pin({required this.parada, required this.onTap});

  final Parada parada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    // El tamaño del pin es fijo: se limita la escala del texto y se ajusta.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        container: true,
        button: true,
        label: 'Parada ${parada.nombre}, abrir detalle',
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: esquema.surfaceContainerLowest,
          shape: StadiumBorder(
            side: BorderSide(color: esquema.outline, width: 2.5),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    parada.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: esquema.onSurface,
                    ),
                  ),
                ),
              ),
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
    final esquema = Theme.of(context).colorScheme;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        label: 'Tu ubicación (simulada)',
        excludeSemantics: true,
        child: Container(
          decoration: BoxDecoration(
            color: esquema.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.my_location, color: esquema.onPrimary, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Tú (simulado)',
                    style: TextStyle(
                      color: esquema.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(color: Colors.black, fontSize: 13),
        ),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Semantics(
          liveRegion: true,
          child: Caja(
            grosor: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(child: Icon(Icons.cloud_off, size: 32)),
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
