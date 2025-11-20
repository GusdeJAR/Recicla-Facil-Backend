import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

class PerfilService {
  // ===================================================================
  // DETECTAR IP AUTOMÁTICAMENTE
  // ===================================================================
  static const String _ipDesarrolloLocal = '192.168.137.115'; // <- TU IP

  // --- URL de producción ---
  static const String _urlProduccion = 'https://recicla-facil-backend.vercel.app'; // <- TU DOMINIO DE VERCEL

  /// **Este getter elige la URL BASE COMPLETA correcta según la plataforma.**
  static String get apiBaseUrl {
    // SI ESTAMOS EN PRODUCCIÓN (compilado con `flutter build`):
    if (kReleaseMode) {
      // Usamos la URL absoluta de tu despliegue en Vercel.
      return _urlProduccion;
    }

    // SI ESTAMOS EN DESARROLLO (ejecutado con `flutter run`):
    if (kIsWeb) {
      // Desarrollo en web: apunta a localhost.
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      // Emulador de Android: apunta a la IP especial del emulador.
      return 'http://10.0.2.2:3000';
    }
    // Dispositivo físico (iOS/Android): apunta a la IP de tu PC.
    return 'http://$_ipDesarrolloLocal:3000';
  }

  // ===================================================================
  // 1. OBTENER PERFIL DE USUARIO
  // ===================================================================
  static Future<Map<String, dynamic>> getUserProfile(String email) async {
    final url = Uri.parse('$apiBaseUrl/api/usuarios/'+email);
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
    final url = Uri.parse('$apiBaseUrl/api/usuarios/cambiar-password');
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
    final url = Uri.parse('$apiBaseUrl/api/usuarios/email');
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