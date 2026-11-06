// Estado de la app en memoria (sin persistencia en esta iteración).

import 'package:flutter/foundation.dart';

/// Pestañas de la barra inferior.
enum Pestana { buscar, lineas, paradas, mapa, ajustes }

/// Petición de precargar origen o destino en «Buscar ruta».
class Precarga {
  const Precarga({this.origenId, this.destinoId});
  final String? origenId;
  final String? destinoId;
}

class EstadoApp {
  // Ajustes (P8).
  final altoContraste = ValueNotifier<bool>(false);
  final antelacion = ValueNotifier<int>(2);
  final sonidoAviso = ValueNotifier<bool>(false);

  // Navegación entre pestañas.
  final pestana = ValueNotifier<Pestana>(Pestana.buscar);

  // Precarga de origen/destino desde el detalle de parada (P5 → P1).
  final precarga = ValueNotifier<Precarga?>(null);

  void irA(Pestana p) => pestana.value = p;

  void usarComoOrigen(String paradaId) {
    precarga.value = Precarga(origenId: paradaId);
    irA(Pestana.buscar);
  }

  void usarComoDestino(String paradaId) {
    precarga.value = Precarga(destinoId: paradaId);
    irA(Pestana.buscar);
  }
}

/// Estado único de la app (prototipo: global y sencillo).
final estado = EstadoApp();
