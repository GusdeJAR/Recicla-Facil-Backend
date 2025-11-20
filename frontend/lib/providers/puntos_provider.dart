// providers/puntos_provider.dart

import 'package:flutter/material.dart';
import '../../models/punto_reciclaje.dart';
import '../../services/puntos_reciclaje_service.dart';

class PuntosProvider with ChangeNotifier {
  List<PuntoReciclaje> _puntos = [];
  bool _isLoading = false;

  // Getters para que los widgets puedan acceder a los datos de forma segura
  List<PuntoReciclaje> get puntos => _puntos;
  bool get isLoading => _isLoading;

  // El método clave para cargar y recargar los datos
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Notifica a los widgets para que se reconstruyan (ej: mostrar un spinner)
  }
  Future<bool> eliminarPunto(String puntoId) async {
    // 1. Inicia el estado de carga
    setLoading(true);

    try {
      // 2. Llama al servicio
      bool exito = await PuntosReciclajeService.eliminarPuntoReciclaje(puntoId);

      if (exito) {
        // 3. Si tuvo éxito, recarga la lista de puntos para que el eliminado desaparezca
        await cargarPuntos(); // Reutilizamos el método de carga
      }

      // 4. Detiene el estado de carga (esto se ejecuta si hubo éxito o no)
      setLoading(false);
      return exito;

    } catch (e) {
      debugPrint("Error en PuntosProvider al eliminar: $e");
      setLoading(false); // Asegúrate de detener la carga también en caso de error
      return false;
    }
  }
  Future<void> cargarPuntos({String material = 'Todos'}) async {
    // Evita cargas múltiples si ya se está cargando
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners(); // Notifica a los widgets que la carga ha comenzado

    try {
      final List<dynamic> datosCrudos = await PuntosReciclajeService.obtenerPuntosReciclajePorMaterial(material);
      _puntos = datosCrudos
          .map((mapa) => PuntoReciclaje.fromJson(mapa as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Manejar el error apropiadamente
      _puntos = [];
      debugPrint("Error en PuntosProvider: $e");
    }

    _isLoading = false;
    notifyListeners(); // Notifica a los widgets que la carga ha terminado y los datos están listos
  }
}
