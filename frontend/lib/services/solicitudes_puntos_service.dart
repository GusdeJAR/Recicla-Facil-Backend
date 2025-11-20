// services/solicitudes_puntos_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rf_sprint1/models/solicitud_punto.dart';

class SolicitudesPuntosService {
  static const String _apiProduccion = '/api';
  static const String _direccionIpLocal = '192.168.137.115'; // <- CAMBIA ESTO POR TU IP

  // 2. LÓGICA DE ASIGNACIÓN: Este getter elige la IP correcta según la plataforma.
  static String get _apiRoot {
    if (kReleaseMode) {
      return _apiProduccion;
    }

    // ASIGNACIÓN PARA WEB:
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    // ASIGNACIÓN PARA MÓVIL (Android):

    if (Platform.isAndroid) {
      // En el emulador de Android, se "asigna" la IP especial del alias.
      return 'http://10.0.2.2:3000/api';
    }


    // ASIGNACIÓN PARA MÓVIL (iOS o dispositivo físico):
    // Se "asigna" la IP de desarrollo configurada manualmente.
    return 'http://$_direccionIpLocal:3000/api';
  }
  // Método para obtener los headers con autenticación
  Map<String, String> _getHeaders(String? userName, bool isAdmin) => {
    'Content-Type': 'application/json',
    if (userName != null) 'x-usuario': userName,
    if (isAdmin) 'x-admin': 'true',
  };

  // Lista actualizada de tipos de materiales disponibles
  List<String> get tiposMaterialDisponibles => ['Todos', 'Aluminio', 'Cartón', 'Papel', 'PET', 'Vidrio'];

  // Crear una nueva solicitud de punto de reciclaje 
  Future<bool> crearSolicitud(SolicitudPunto solicitud, {Map<String, dynamic>? ubicacion, required String userName, bool isAdmin = false}) async {
    try {
      final bodyMap = solicitud.toJson();
      if (ubicacion != null) {
        bodyMap['ubicacion'] = ubicacion;
      }
      final response = await http.post(
        Uri.parse('$_apiRoot/solicitudes-puntos'),
        headers: _getHeaders(userName, isAdmin),
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error al crear solicitud: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en crearSolicitud: $e');
      return false;
    }
  }

  // Obtener todas las solicitudes 
  Future<List<SolicitudPunto>> obtenerTodasLasSolicitudes({required String userName, bool isAdmin = false}) async {
    try {
      // El backend define rutas distintas: los administradores usan
      // '/solicitudes-puntos/admin/todas' y los usuarios normales usan
      // '/solicitudes-puntos/mis-solicitudes'. Evitamos el 404 eligiendo
      // la ruta según el rol.
      final uri = isAdmin
          ? Uri.parse('$_apiRoot/solicitudes-puntos/admin/todas')
          : Uri.parse('$_apiRoot/solicitudes-puntos/mis-solicitudes');

      final response = await http.get(
        uri,
        headers: _getHeaders(userName, isAdmin),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // El backend devuelve {success: true, data: [...]}
        final List<dynamic> solicitudesData = responseData['data'] ?? [];
        return solicitudesData.map((json) => SolicitudPunto.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar solicitudes: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en obtenerTodasLasSolicitudes: $e');
      throw Exception('Error de conexión al cargar las solicitudes: $e');
    }
  }

  // Obtener las solicitudes de un usuario específico 
  Future<List<SolicitudPunto>> obtenerSolicitudesPorUsuario(String usuarioNombre, {required String userName, bool isAdmin = false}) async {
    try {
      final todasSolicitudes = await obtenerTodasLasSolicitudes(userName: userName, isAdmin: isAdmin);
      // Filtrar por nombre de usuario en el frontend
      return todasSolicitudes.where((solicitud) => 
        solicitud.usuarioSolicitante == usuarioNombre
      ).toList();
    } catch (e) {
      print('Excepción en obtenerSolicitudesPorUsuario: $e');
      throw Exception('Error al cargar las solicitudes del usuario: $e');
    }
  }

  // Obtener todas las solicitudes pendientes 
  Future<List<SolicitudPunto>> obtenerSolicitudesPendientes({required String userName, bool isAdmin = false}) async {
    try {
      final todasSolicitudes = await obtenerTodasLasSolicitudes(userName: userName, isAdmin: isAdmin);
      return todasSolicitudes.where((solicitud) => solicitud.estado == 'pendiente').toList();
    } catch (e) {
      print('Excepción en obtenerSolicitudesPendientes: $e');
      throw Exception('Error al cargar las solicitudes pendientes: $e');
    }
  }

  // Obtener solicitudes por estado 
  Future<List<SolicitudPunto>> obtenerSolicitudesPorEstado(String estado, {required String userName, bool isAdmin = false}) async {
    try {
      final todasSolicitudes = await obtenerTodasLasSolicitudes(userName: userName, isAdmin: isAdmin);
      return todasSolicitudes.where((solicitud) => solicitud.estado == estado).toList();
    } catch (e) {
      print('Excepción en obtenerSolicitudesPorEstado: $e');
      throw Exception('Error al cargar las solicitudes por estado: $e');
    }
  }

  // Aprobar una solicitud 
  Future<bool> aprobarSolicitud(String solicitudId, {String? comentariosAdmin, required String userName, bool isAdmin = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiRoot/solicitudes-puntos/admin/$solicitudId/aprobar'),
        headers: _getHeaders(userName, isAdmin),
        body: jsonEncode({
          'comentariosAdmin': comentariosAdmin ?? 'Solicitud aprobada',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al aprobar solicitud: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en aprobarSolicitud: $e');
      return false;
    }
  }

  // Rechazar una solicitud 
  Future<bool> rechazarSolicitud(String solicitudId, String comentariosAdmin, {required String userName, bool isAdmin = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiRoot/solicitudes-puntos/admin/$solicitudId/rechazar'),
        headers: _getHeaders(userName, isAdmin),
        body: jsonEncode({
          'comentariosAdmin': comentariosAdmin,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al rechazar solicitud: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en rechazarSolicitud: $e');
      return false;
    }
  }

  // Obtener estadísticas de solicitudes 
  Future<Map<String, int>> obtenerEstadisticasSolicitudes({required String userName, bool isAdmin = false}) async {
    try {
      final todasSolicitudes = await obtenerTodasLasSolicitudes(userName: userName, isAdmin: isAdmin);
      
      final estadisticas = {
        'total': todasSolicitudes.length,
        'pendientes': todasSolicitudes.where((s) => s.estado == 'pendiente').length,
        'aprobadas': todasSolicitudes.where((s) => s.estado == 'aprobada').length,
        'rechazadas': todasSolicitudes.where((s) => s.estado == 'rechazada').length,
      };
      
      return estadisticas;
    } catch (e) {
      print('Excepción en obtenerEstadisticasSolicitudes: $e');
      throw Exception('Error al cargar las estadísticas: $e');
    }
  }

  // Método auxiliar para obtener detalles de una solicitud específica 
  Future<SolicitudPunto> obtenerSolicitudPorId(String solicitudId, {required String userName, bool isAdmin = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiRoot/solicitudes-puntos/$solicitudId'),
        headers: _getHeaders(userName, isAdmin),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return SolicitudPunto.fromJson(data);
      } else {
        throw Exception('Error al cargar la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en obtenerSolicitudPorId: $e');
      throw Exception('Error de conexión al cargar la solicitud: $e');
    }
  }

  // Método para cancelar una solicitud propia 
  Future<bool> cancelarSolicitud(String solicitudId, {required String userName, bool isAdmin = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiRoot/solicitudes-puntos/$solicitudId'),
        headers: _getHeaders(userName, isAdmin),
        body: jsonEncode({
          'estado': 'cancelada',
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al cancelar solicitud: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en cancelarSolicitud: $e');
      return false;
    }
  }

  // Método para actualizar una solicitud 
  Future<bool> actualizarSolicitud(String solicitudId, SolicitudPunto solicitud, {required String userName, bool isAdmin = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiRoot/solicitudes-puntos/$solicitudId'),
        headers: _getHeaders(userName, isAdmin),
        body: jsonEncode(solicitud.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al actualizar solicitud: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en actualizarSolicitud: $e');
      return false;
    }
  }
}