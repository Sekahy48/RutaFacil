// P1 · Buscar ruta (pantalla inicial).

import 'package:flutter/material.dart';

import '../../data/datos_mock.dart';
import '../../data/planificador.dart';
import '../../estado.dart';
import '../comunes.dart';
import 'p7_seguimiento.dart';

class PantallaBuscar extends StatefulWidget {
  const PantallaBuscar({super.key});

  @override
  State<PantallaBuscar> createState() => _PantallaBuscarState();
}

enum _Campo { origen, destino }

class _PantallaBuscarState extends State<PantallaBuscar> {
  final _ctrlOrigen = TextEditingController();
  final _ctrlDestino = TextEditingController();
  final _focoOrigen = FocusNode();
  final _focoDestino = FocusNode();
  final _focoBoton = FocusNode();

  String? _errorOrigen;
  String? _errorDestino;
  String? _errorGeneral;
  List<Trayecto>? _resultados;

  @override
  void initState() {
    super.initState();
    _focoOrigen.addListener(_refrescar);
    _focoDestino.addListener(_refrescar);
    estado.precarga.addListener(_aplicarPrecarga);
  }

  @override
  void dispose() {
    estado.precarga.removeListener(_aplicarPrecarga);
    _ctrlOrigen.dispose();
    _ctrlDestino.dispose();
    _focoOrigen.dispose();
    _focoDestino.dispose();
    _focoBoton.dispose();
    super.dispose();
  }

  void _refrescar() => setState(() {});

  void _limpiarResultados() {
    _errorOrigen = null;
    _errorDestino = null;
    _errorGeneral = null;
    _resultados = null;
  }

  void _aplicarPrecarga() {
    final p = estado.precarga.value;
    if (p == null) return;
    estado.precarga.value = null;
    setState(() {
      _limpiarResultados();
      if (p.origenId != null) {
        _ctrlOrigen.text = paradaPorId(p.origenId!).nombre;
      }
      if (p.destinoId != null) {
        _ctrlDestino.text = paradaPorId(p.destinoId!).nombre;
      }
    });
    final texto = p.origenId != null
        ? 'Origen: ${paradaPorId(p.origenId!).nombre}.'
        : 'Destino: ${paradaPorId(p.destinoId!).nombre}.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) anunciar(context, texto);
    });
  }

  void _elegirSugerencia(_Campo campo, Parada p) {
    setState(() {
      _limpiarResultados();
      if (campo == _Campo.origen) {
        _ctrlOrigen.text = p.nombre;
        _focoDestino.requestFocus();
      } else {
        _ctrlDestino.text = p.nombre;
        _focoBoton.requestFocus();
      }
    });
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    final origen = paradaPorNombre(_ctrlOrigen.text);
    final destino = paradaPorNombre(_ctrlDestino.text);

    setState(() {
      _limpiarResultados();
      if (origen == null) {
        _errorOrigen = 'Elige una parada de origen de la lista.';
      }
      if (destino == null) {
        _errorDestino = 'Elige una parada de destino de la lista.';
      }
      if (origen != null && destino != null && origen.id == destino.id) {
        _errorGeneral =
            'Error: origen y destino son la misma parada. Cambia el destino.';
        _errorDestino = 'Es la misma parada que el origen.';
      }
    });

    final hayError =
        _errorOrigen != null || _errorDestino != null || _errorGeneral != null;
    if (hayError) {
      final mensaje =
          _errorGeneral ??
          [_errorOrigen, _errorDestino].whereType<String>().join(' ');
      anunciar(context, mensaje);
      // Foco al campo que hay que corregir.
      (_errorOrigen != null ? _focoOrigen : _focoDestino).requestFocus();
      return;
    }

    final res = buscarTrayectos(origen!.id, destino!.id);
    setState(() => _resultados = res);
    anunciar(
      context,
      res.isEmpty
          ? 'No hay trayectos entre ${origen.nombre} y ${destino.nombre}.'
          : '${_textoEncontrados(res.length)}. El más rápido tarda '
                '${res.first.duracion} minutos.',
    );
  }

  String _textoEncontrados(int n) =>
      n == 1 ? '1 trayecto encontrado' : '$n trayectos encontrados';

  Future<void> _elegir(Trayecto t) async {
    final terminado = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<bool>(builder: (_) => PantallaSeguimiento(trayecto: t)),
    );
    if (terminado == true && mounted) {
      setState(() {
        _limpiarResultados();
        _ctrlOrigen.clear();
        _ctrlDestino.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Pantalla(
      titulo: 'Buscar ruta',
      cuerpo: QuitarFocoAlTocar(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _campo(_Campo.origen),
            const SizedBox(height: 20),
            _campo(_Campo.destino),
            if (_errorGeneral != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Caja(
                  grosor: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.error_outline,
                          size: 28,
                          color: esquema.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorGeneral!,
                          style: tt.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              focusNode: _focoBoton,
              onPressed: _buscar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
              ),
              child: const Text('Buscar trayecto', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            Text(
              'Horarios teóricos desde las ${hhmm(minutoReferencia())} '
              '(sin tiempo real). Datos de ejemplo.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ..._zonaResultados(),
          ],
        ),
      ),
    );
  }

  Widget _campo(_Campo campo) {
    final esOrigen = campo == _Campo.origen;
    final ctrl = esOrigen ? _ctrlOrigen : _ctrlDestino;
    final foco = esOrigen ? _focoOrigen : _focoDestino;
    final error = esOrigen ? _errorOrigen : _errorDestino;
    final etiqueta = esOrigen ? 'Origen' : 'Destino';
    final tt = Theme.of(context).textTheme;

    // Sugerencias: solo en el campo con foco y si el texto no es ya una
    // parada exacta.
    final sugerencias = foco.hasFocus && paradaPorNombre(ctrl.text) == null
        ? buscarParadas(ctrl.text)
        : const <Parada>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: ctrl,
          focusNode: foco,
          style: tt.bodyLarge,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(_limpiarResultados),
          onSubmitted: (_) {
            final s = buscarParadas(ctrl.text);
            if (s.length == 1) {
              _elegirSugerencia(campo, s.first);
            }
          },
          decoration: InputDecoration(
            labelText: etiqueta,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: tt.titleMedium,
            hintText: 'Escribe o elige una parada',
            errorText: error,
            errorMaxLines: 4,
            suffixIcon: ctrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar $etiqueta',
                    style: IconButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: Colors.transparent,
                    ),
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        ctrl.clear();
                        _limpiarResultados();
                      });
                      foco.requestFocus();
                    },
                  ),
          ),
        ),
        if (sugerencias.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Caja(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final p in sugerencias)
                    Semantics(
                      container: true,
                      button: true,
                      label:
                          'Elegir ${p.nombre} como ${etiqueta.toLowerCase()}',
                      onTap: () => _elegirSugerencia(campo, p),
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => _elegirSugerencia(campo, p),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(p.nombre, style: tt.bodyLarge),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _zonaResultados() {
    final tt = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final res = _resultados;

    if (res == null) {
      if (_errorGeneral != null ||
          _errorOrigen != null ||
          _errorDestino != null) {
        return const [];
      }
      return [
        Text(
          'Aún no hay trayectos. Elige origen y destino.',
          textAlign: TextAlign.center,
          style: tt.bodyLarge?.copyWith(color: esquema.onSurfaceVariant),
        ),
      ];
    }
    if (res.isEmpty) {
      return [
        Caja(
          child: Text(
            'No hay trayectos con los datos de ejemplo entre '
            '${_ctrlOrigen.text} y ${_ctrlDestino.text}. '
            'Las líneas solo van en un sentido.',
            style: tt.bodyLarge,
          ),
        ),
      ];
    }

    final apilar = MediaQuery.textScalerOf(context).scale(10) > 14;
    return [
      TituloSeccion(_textoEncontrados(res.length)),
      const SizedBox(height: 12),
      for (var i = 0; i < res.length; i++) ...[
        _tarjeta(i + 1, res[i], apilar),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _tarjeta(int n, Trayecto t, bool apilar) {
    final tt = Theme.of(context).textTheme;
    final detalle = '${t.duracion} min · ${t.textoTrasbordo}';
    final horas =
        'Sale ${hhmm(t.salida)} de ${t.origen.nombre} · llega ${hhmm(t.llegada)}';

    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Opción $n · ${t.nombreLineas}', style: tt.titleMedium),
        const SizedBox(height: 4),
        Text(detalle, style: tt.bodyLarge),
        const SizedBox(height: 4),
        Text(horas, style: tt.bodyMedium),
      ],
    );
    final boton = OutlinedButton(
      onPressed: () => _elegir(t),
      style: OutlinedButton.styleFrom(minimumSize: const Size(110, 56)),
      child: Semantics(
        label: 'Elegir opción $n',
        excludeSemantics: true,
        child: const Text('Elegir'),
      ),
    );

    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TalkBack lee la tarjeta entera como un bloque.
          MergeSemantics(
            child: apilar
                ? textos
                : Row(
                    children: [
                      Expanded(child: textos),
                      const SizedBox(width: 12),
                      boton,
                    ],
                  ),
          ),
          if (apilar) ...[const SizedBox(height: 12), boton],
        ],
      ),
    );
  }
}
