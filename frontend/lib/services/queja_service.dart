import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/queja.dart';

class QuejaService {
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

  // ===================================================================
  // 1. CREAR QUEJA
  // ===================================================================
  Future<Map<String, dynamic>> crearQueja({
    required String correo,
    required String categoria,
    required String mensaje
  }) async {
    final url = Uri.parse('$_apiRoot/quejas');
    debugPrint('QuejaService - Creando queja en: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'correo': correo,
          'categoria': categoria,
          'mensaje': mensaje
        }),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseData = json.decode(response.body);
      responseData['statusCode'] = response.statusCode;
      return responseData;

    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===================================================================
  // 2. OBTENER MIS QUEJAS
  // ===================================================================
  Future<List<Queja>> obtenerMisQuejas(String email) async {
    final url = Uri.parse('$_apiRoot/quejas/mis-quejas/$email');
    debugPrint('QuejaService - Obteniendo mis quejas en: $url');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return quejaFromJson(response.body);
      } else {
        throw Exception('Error al cargar tus quejas: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // ===================================================================
  // 3. OBTENER QUEJAS POR CATEGORÍA
  // ===================================================================
  Future<List<Queja>> obtenerQuejasPorCategoria(String categoria) async {
    final String categoriaCodificada = Uri.encodeComponent(categoria);
    final url = Uri.parse('$_apiRoot/quejas/categoria/$categoriaCodificada');
    debugPrint('QuejaService - Obteniendo quejas por categoría en: $url');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return quejaFromJson(response.body);
      } else {
        throw Exception('Error al cargar quejas por categoría: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // ===================================================================
  // 4. OBTENER QUEJAS PENDIENTES
  // ===================================================================
  Future<List<Queja>> obtenerQuejasPendientes() async {
    final url = Uri.parse('$_apiRoot/quejas/pendientes');
    debugPrint('QuejaService - Obteniendo quejas pendientes en: $url');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return quejaFromJson(response.body);
      } else {
        throw Exception('Error al cargar quejas pendientes: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // ===================================================================
  // 5. ATENDER QUEJA
  // ===================================================================
  Future<Map<String, dynamic>> atenderQueja(String quejaId, String respuestaAdmin) async {
    final url = Uri.parse('$_apiRoot/quejas/$quejaId');
    debugPrint('QuejaService - Atendiendo queja en: $url');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'respuestaAdmin': respuestaAdmin}),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseData = json.decode(response.body);
      responseData['statusCode'] = response.statusCode;
      return responseData;

    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al atender la queja: $e');
    }
  }

  // ===================================================================
  // 6. ELIMINAR QUEJA
  // ===================================================================
  Future<Map<String, dynamic>> eliminarQueja(String quejaId) async {
    final url = Uri.parse('$_apiRoot/quejas/$quejaId');
    debugPrint('QuejaService - Eliminando queja en: $url');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseData = json.decode(response.body);
      responseData['statusCode'] = response.statusCode;
      return responseData;

    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al eliminar la queja: $e');
    }
  }
}