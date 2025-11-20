// lib/providers/admin_solicitudes_provider.dart

import 'package:flutter/material.dart';
import 'package:rf_sprint1/models/solicitud_punto.dart';
import 'package:rf_sprint1/services/solicitudes_puntos_service.dart';

class AdminSolicitudesProvider with ChangeNotifier {
  final SolicitudesPuntosService _service = SolicitudesPuntosService();
  List<SolicitudPunto> _solicitudesPendientes = [];
  bool _isLoading = false;

  List<SolicitudPunto> get solicitudesPendientes => _solicitudesPendientes;
  bool get isLoading => _isLoading;

  // Carga SOLO las solicitudes pendientes para el administrador
  Future<void> cargarSolicitudesPendientes(String userName, bool isAdmin) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _solicitudesPendientes = await _service.obtenerSolicitudesPendientes(
        userName: userName,
        isAdmin: isAdmin,
      );
    } catch (e) {
      debugPrint('Error en AdminSolicitudesProvider: $e');
      _solicitudesPendientes = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
