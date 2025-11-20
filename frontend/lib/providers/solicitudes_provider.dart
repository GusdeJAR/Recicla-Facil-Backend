// lib/providers/solicitudes_provider.dart

import 'package:flutter/material.dart';
import 'package:rf_sprint1/models/solicitud_punto.dart';
import 'package:rf_sprint1/services/solicitudes_puntos_service.dart';

class SolicitudesProvider with ChangeNotifier {
  final SolicitudesPuntosService _service = SolicitudesPuntosService();
  List<SolicitudPunto> _solicitudes = [];
  bool _isLoading = false;

  // Getters públicos para que la UI acceda a los datos
  List<SolicitudPunto> get solicitudes => _solicitudes;
  bool get isLoading => _isLoading;

  // Método para cargar/recargar las solicitudes de un usuario específico
  Future<void> cargarSolicitudesUsuario(String userName, bool isAdmin) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners(); // Notifica que la carga ha comenzado

    try {
      _solicitudes = await _service.obtenerSolicitudesPorUsuario(
        userName,
        userName: userName,
        isAdmin: isAdmin,
      );
    } catch (e) {
      debugPrint('Error en SolicitudesProvider: $e');
      _solicitudes = []; // En caso de error, la lista queda vacía
    }

    _isLoading = false;
    notifyListeners(); // Notifica que la carga ha terminado y hay nuevos datos
  }
}
