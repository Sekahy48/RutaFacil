// P1 · Buscar ruta (pantalla inicial).

import 'package:flutter/material.dart';

import '../../data/paradas_lineas.dart';
import '../../data/planificador.dart';
import '../../estado.dart';
import '../comunes.dart';
import '../tema.dart';
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
        _errorOrigen = _mensajeNoEncontrada(_ctrlOrigen.text, 'origen');
      }
      if (destino == null) {
        _errorDestino = _mensajeNoEncontrada(_ctrlDestino.text, 'destino');
      }
      if (origen != null && destino != null && origen.id == destino.id) {
        _errorGeneral =
            'origen y destino son la misma parada. Cambia el destino por '
            'otra parada.';
        _errorDestino =
            'es la misma parada que el origen. Escribe y elige otra parada.';
      }
    });

    final hayError =
        _errorOrigen != null || _errorDestino != null || _errorGeneral != null;
    if (hayError) {
      final mensaje = _errorGeneral != null
          ? 'Error: $_errorGeneral'
          : [
              if (_errorOrigen != null) 'Error en origen: $_errorOrigen',
              if (_errorDestino != null) 'Error en destino: $_errorDestino',
            ].join(' ');
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

  /// Qué ha pasado y cómo corregirlo (sin el prefijo «Error:»).
  String _mensajeNoEncontrada(String texto, String campo) {
    final t = texto.trim();
    if (t.isEmpty) {
      return 'no has escrito el $campo. Escribe parte del nombre y elige '
          'una parada de la lista.';
    }
    return '«$t» no es una parada de la lista. Escribe parte del nombre y '
        'elige una de las sugerencias.';
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
              const SizedBox(height: 2 * kEspacio),
              CajaError(_errorGeneral!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              focusNode: _focoBoton,
              onPressed: _buscar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kAltoBotonPrincipal),
              ),
              child: const Text('Buscar trayecto', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            Text(
              'Horarios teóricos desde las ${hhmm(minutoReferencia())} '
              '(sin tiempo real). Datos de ejemplo.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: context.paleta.textoSecundario,
              ),
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
        CampoTexto(
          etiqueta: etiqueta,
          controller: ctrl,
          focusNode: foco,
          pista: 'Escribe o elige una parada',
          error: error,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(_limpiarResultados),
          onSubmitted: (_) {
            final s = buscarParadas(ctrl.text);
            if (s.length == 1) {
              _elegirSugerencia(campo, s.first);
            }
          },
          onBorrar: () {
            setState(() {
              ctrl.clear();
              _limpiarResultados();
            });
            foco.requestFocus();
          },
        ),
        if (sugerencias.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: kEspacio),
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
                      child: Tocable(
                        onTap: () => _elegirSugerencia(campo, p),
                        anilloDentro: true,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2 * kEspacio,
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
          style: tt.bodyLarge?.copyWith(color: context.paleta.textoSecundario),
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
        const SizedBox(height: kEspacio),
        Wrap(
          spacing: kEspacio,
          runSpacing: 4,
          children: [for (final tr in t.tramos) EtiquetaLinea(tr.linea.id)],
        ),
        const SizedBox(height: kEspacio),
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
