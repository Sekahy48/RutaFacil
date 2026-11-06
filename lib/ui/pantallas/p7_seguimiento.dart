// P7 · Seguimiento del trayecto (sin barra inferior).
// El avance es SIMULADO con botones: no hay GPS ni tiempo real.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/datos_mock.dart';
import '../../data/planificador.dart';
import '../../estado.dart';
import '../comunes.dart';

enum _TipoPaso { espera, viaje, trasbordo, llegada }

class _Paso {
  const _Paso(this.tipo, this.tramo, this.texto);
  final _TipoPaso tipo;
  final int tramo;
  final String texto;
}

class PantallaSeguimiento extends StatefulWidget {
  const PantallaSeguimiento({super.key, required this.trayecto});

  final Trayecto trayecto;

  @override
  State<PantallaSeguimiento> createState() => _PantallaSeguimientoState();
}

class _PantallaSeguimientoState extends State<PantallaSeguimiento> {
  /// Paradas de todo el trayecto en orden (el trasbordo aparece una vez).
  late final List<Parada> _paradas;

  /// Posición (en [_paradas]) de subida y bajada de cada tramo.
  late final List<int> _inicioTramo;
  late final List<int> _finTramo;
  late final List<_Paso> _pasos;

  int _paso = 0;
  int _pos = 0;

  Trayecto get _t => widget.trayecto;

  @override
  void initState() {
    super.initState();
    _paradas = [];
    _inicioTramo = [];
    _finTramo = [];
    for (final tramo in _t.tramos) {
      final ps = tramo.paradas;
      if (_paradas.isEmpty) {
        _inicioTramo.add(0);
        _paradas.addAll(ps);
      } else {
        _inicioTramo.add(_paradas.length - 1);
        _paradas.addAll(ps.skip(1));
      }
      _finTramo.add(_paradas.length - 1);
    }

    _pasos = [];
    for (var i = 0; i < _t.tramos.length; i++) {
      final tr = _t.tramos[i];
      if (i == 0) {
        _pasos.add(
          _Paso(
            _TipoPaso.espera,
            i,
            'Espera en ${tr.paradaSubida.nombre} la ${tr.linea.nombre} '
            '(sale a las ${hhmm(tr.salida)}).',
          ),
        );
      } else {
        _pasos.add(
          _Paso(
            _TipoPaso.trasbordo,
            i,
            'Bájate en ${tr.paradaSubida.nombre} y espera la '
            '${tr.linea.nombre} (sale a las ${hhmm(tr.salida)}).',
          ),
        );
      }
      _pasos.add(
        _Paso(
          _TipoPaso.viaje,
          i,
          'Sube a la ${tr.linea.nombre}, dirección ${tr.linea.destino}. '
          'Bájate en ${tr.paradaBajada.nombre}.',
        ),
      );
    }
    _pasos.add(
      _Paso(
        _TipoPaso.llegada,
        _t.tramos.length - 1,
        'Bájate en ${_t.destino.nombre}.',
      ),
    );
  }

  _Paso get _pasoActual => _pasos[_paso];
  bool get _llegado => _pasoActual.tipo == _TipoPaso.llegada;
  int get _finActual => _finTramo[_pasoActual.tramo];
  int get _faltan => _finActual - _pos;
  Parada get _bajada => _paradas[_finActual];
  int get _antelacion => estado.antelacion.value;

  bool get _avisoVisible =>
      _pasoActual.tipo == _TipoPaso.viaje &&
      _faltan > 0 &&
      _faltan <= _antelacion;

  int _posInicial(int paso) {
    final p = _pasos[paso];
    return p.tipo == _TipoPaso.llegada
        ? _finTramo[p.tramo]
        : _inicioTramo[p.tramo];
  }

  /// Aplica un cambio y lanza aviso / anuncio si corresponde.
  void _cambiar(VoidCallback cambio) {
    final avisoAntes = _avisoVisible;
    final faltanAntes = _faltan;
    final pasoAntes = _paso;
    setState(cambio);

    if (_llegado && pasoAntes != _paso) {
      _alertar();
      anunciar(
        context,
        'Has llegado a tu parada: ${_t.destino.nombre}. Bájate aquí.',
      );
    } else if (_pasoActual.tipo == _TipoPaso.trasbordo && pasoAntes != _paso) {
      _alertar();
      anunciar(context, _pasoActual.texto);
    } else if (_avisoVisible && (!avisoAntes || _faltan != faltanAntes)) {
      _alertar();
      anunciar(context, 'Aviso. Prepárate: ${_textoTeBajas()}.');
    } else {
      anunciar(
        context,
        'Paso ${_paso + 1} de ${_pasos.length}. ${_pasoActual.texto} '
        'Parada actual: ${_paradas[_pos].nombre}.',
      );
    }
  }

  /// Vibración (siempre) y sonido (si está activado en Ajustes).
  void _alertar() {
    HapticFeedback.heavyImpact();
    if (estado.sonidoAviso.value) {
      // En Android solo existe el sonido de «clic» del sistema.
      SystemSound.play(SystemSoundType.click);
    }
  }

  String _paradasTxt(int n) => n == 1 ? '1 parada' : '$n paradas';

  String _textoTeBajas() =>
      'te bajas en ${_paradasTxt(_faltan)}: ${_bajada.nombre}';

  void _anterior() => _cambiar(() {
    _paso--;
    _pos = _posInicial(_paso);
  });

  void _siguiente() => _cambiar(() {
    _paso++;
    _pos = _posInicial(_paso);
  });

  void _hePasado() => _cambiar(() {
    if (_pasoActual.tipo != _TipoPaso.viaje) _paso++;
    _pos++;
    if (_pos >= _finActual) _paso++;
  });

  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: const Text('¿Salir del seguimiento?'),
        ),
        content: const Text('Dejarás de recibir avisos de este trayecto.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (salir == true && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final apilar = MediaQuery.textScalerOf(context).scale(10) > 14;

    final anterior = OutlinedButton(
      onPressed: _paso > 0 ? _anterior : null,
      child: const Text('Paso anterior', textAlign: TextAlign.center),
    );
    final siguiente = OutlinedButton(
      onPressed: _paso < _pasos.length - 1 ? _siguiente : null,
      child: const Text('Paso siguiente', textAlign: TextAlign.center),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSalida();
      },
      child: Pantalla(
        titulo: 'Trayecto en curso',
        accion: OutlinedButton(
          onPressed: _confirmarSalida,
          child: Semantics(
            label: 'Salir del seguimiento',
            excludeSemantics: true,
            child: const Text('Salir'),
          ),
        ),
        cuerpo: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            if (_avisoVisible) ...[
              Semantics(
                liveRegion: true,
                child: Caja(
                  grosor: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.notifications_active,
                          size: 32,
                          color: esquema.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AVISO · Prepárate', style: tt.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Te bajas en ${_paradasTxt(_faltan)}:',
                              style: tt.bodyLarge,
                            ),
                            Text(
                              _bajada.nombre,
                              style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_llegado) ...[
              Semantics(
                liveRegion: true,
                child: Caja(
                  grosor: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '✓ Has llegado a tu parada',
                        style: tt.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(_t.destino.nombre, style: tt.titleLarge),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(64),
                        ),
                        child: const Text('Terminar trayecto'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              MergeSemantics(
                child: Caja(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Te bajas en:', style: tt.bodyLarge),
                      Text(_bajada.nombre, style: tt.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Faltan ${_paradasTxt(_faltan)}',
                        style: tt.titleLarge,
                      ),
                      if (_pasoActual.tramo < _t.tramos.length - 1) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Después: ${_t.tramos.last.linea.nombre} '
                          'hasta ${_t.destino.nombre}',
                          style: tt.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Parada actual: ${_paradas[_pos].nombre}',
              style: tt.bodyLarge,
            ),
            const SizedBox(height: 16),
            MergeSemantics(
              child: Caja(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${_paso + 1} de ${_pasos.length}',
                      style: tt.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(_pasoActual.texto, style: tt.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (apilar) ...[
              anterior,
              const SizedBox(height: 12),
              siguiente,
            ] else
              Row(
                children: [
                  Expanded(child: anterior),
                  const SizedBox(width: 16),
                  Expanded(child: siguiente),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _llegado ? null : _hePasado,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
              ),
              child: const Text(
                'He pasado una parada',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aviso: ${_paradasTxt(_antelacion)} antes '
              '(se cambia en Ajustes).\n'
              'Sonido del aviso: '
              '${estado.sonidoAviso.value ? 'activado' : 'desactivado'}. '
              'La vibración siempre está activada.',
              style: tt.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Avance simulado con botones (sin GPS ni tiempo real).',
              style: tt.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
