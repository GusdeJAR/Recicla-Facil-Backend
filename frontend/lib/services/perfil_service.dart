import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

class PerfilService {
  // ===================================================================
  // DETECTAR IP AUTOMÁTICAMENTE
  // ===================================================================
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
  // 1. OBTENER PERFIL DE USUARIO
  // ===================================================================
  static Future<Map<String, dynamic>> getUserProfile(String email) async {
    final url = Uri.parse('$_apiRoot/usuarios/'+email);
    debugPrint('PerfilService - Obteniendo perfil en: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error del servidor [GET PROFILE]: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        throw Exception('Error al cargar perfil: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===================================================================
  // 2. CAMBIAR CONTRASEÑA
  // ===================================================================
  static Future<Map<String, dynamic>> changePassword({
    required String email,
    required String nuevaPassword
  }) async {
    final url = Uri.parse('$_apiRoot/usuarios/cambiar-password');
    debugPrint('PerfilService - Cambiando contraseña en: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'nuevaPassword': nuevaPassword,
        }),
      ).timeout(const Duration(seconds: 10));

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
  // 3. ACTUALIZAR PERFIL 
  // ===================================================================
  static Future<Map<String, dynamic>> updateProfile({
    required String email,
    String? nombre,
    String? nuevoEmail,
  }) async {
    final url = Uri.parse('$_apiRoot/usuarios/email');
    debugPrint('PerfilService - Actualizando perfil en: $url');

    try {
      final Map<String, dynamic> body = {};
      if (nombre != null) body['nombre'] = nombre;
      if (nuevoEmail != null) body['email'] = nuevoEmail;

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = json.decode(response.body);
      responseData['statusCode'] = response.statusCode;
      return responseData;

    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}