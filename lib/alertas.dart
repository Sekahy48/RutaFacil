// Vibración de los avisos de P7 (aviso de bajada, trasbordo y llegada).
//
// Antes se usaba HapticFeedback.heavyImpact(), que en Android es
// view.performHapticFeedback(CONTEXT_CLICK): un «clic» háptico de interfaz
// que depende del ajuste de respuesta táctil del sistema y que en muchos
// móviles apenas se nota o no vibra. Para un aviso hace falta una vibración
// de verdad: se usa el vibrador del dispositivo (paquete `vibration`, permiso
// VIBRATE en AndroidManifest.xml) con un patrón explícito.
//
// La vibración nunca es la única señal: P7 muestra además la caja de aviso
// (⚠ + «AVISO» + borde de 3 dp) y lo anuncia a TalkBack.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Patrón del aviso en ms: espera 0, vibra 400, pausa 200, vibra 400.
const List<int> kPatronAviso = [0, 400, 200, 400];

/// Intensidades del patrón (0–255) si el móvil controla la amplitud.
const List<int> kIntensidadAviso = [0, 255, 0, 255];

/// Función que hace vibrar con un patrón. Se puede sustituir en pruebas.
typedef Vibrador = Future<void> Function(List<int> patron);

class Alertas {
  Alertas({Vibrador? vibrador}) : vibrador = vibrador ?? _vibrarDispositivo;

  /// Implementación en uso (la real, salvo en pruebas).
  Vibrador vibrador;

  /// Vibra con [kPatronAviso]. No lanza excepciones: si falla, lo registra
  /// en el log y el aviso visual y hablado siguen funcionando.
  Future<void> vibrarAviso() async {
    debugPrint('RutaFacil · aviso: vibración $kPatronAviso');
    try {
      await vibrador(kPatronAviso);
    } on Object catch (e) {
      debugPrint('RutaFacil · aviso: no se pudo vibrar ($e)');
    }
  }

  static Future<void> _vibrarDispositivo(List<int> patron) async {
    if (!await Vibration.hasVibrator()) {
      debugPrint('RutaFacil · aviso: el dispositivo no tiene vibrador');
      // Último recurso: el háptico del sistema (puede no notarse).
      await HapticFeedback.heavyImpact();
      return;
    }
    final amplitud = await Vibration.hasAmplitudeControl();
    await Vibration.vibrate(
      pattern: patron,
      intensities: amplitud ? kIntensidadAviso : const [],
    );
  }
}

/// Instancia única de la app.
final alertas = Alertas();
