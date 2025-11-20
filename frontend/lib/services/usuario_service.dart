import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

class UsuarioService {

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
  // 1. LOGIN de un usuario
  // ===================================================================
  Future<Map<String, dynamic>> loginUsuario({
    required String nombre,
    required String password,
  }) async {
    final url = Uri.parse('$apiBaseUrl/api/usuarios/login');
    debugPrint('Haciendo POST a: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'nombre': nombre, 'password': password}),
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
  // 2. CREAR un nuevo usuario
  // ===================================================================
  Future<Map<String, dynamic>> crearUsuario({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$apiBaseUrl/usuarios');
    debugPrint('Haciendo POST a: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'nombre': nombre,
          'email': email,
          'password': password
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = json.decode(response.body);
      responseData['statusCode'] = response.statusCode;
      return responseData;

    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión a internet.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ===================================================================
  // 3. OBTENER todos los usuarios
  // ===================================================================
  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final url = Uri.parse('$apiBaseUrl/usuarios');
    debugPrint('Haciendo GET a: $url');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> usuarios = [];
        for (final item in data) {
          if (item is Map) {
            usuarios.add(Map<String, dynamic>.from(item));
          }
        }
        return usuarios;
      } else {
        debugPrint('Error del servidor [GET]: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        throw Exception('Error al cargar usuarios: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error de conexión o parsing [GET]: $e');
      throw Exception('No se pudo conectar al servidor.');
    }
  }

  // ===================================================================
  // 4. ACTUALIZAR un usuario por su email
  // ===================================================================
  Future<bool> actualizarUsuario({
    required String email,
    String? nombre,
    String? password,
    bool? admin,
  }) async {
    final url = Uri.parse('$apiBaseUrl/usuarios/$email');
    final Map<String, dynamic> body = {};
    if (nombre != null) body['nombre'] = nombre;
    if (password != null) body['password'] = password;
    if (admin != null) body['admin'] = admin;
    if (body.isEmpty) {
      debugPrint("No se proporcionaron datos para actualizar.");
      return false;
    }

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        debugPrint('Usuario actualizado exitosamente.');
        return true;
      } else {
        debugPrint('Error del servidor [PUT]: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error de conexión [PUT]: $e');
      return false;
    }
  }

  // ===================================================================
  // 5. ELIMINAR un usuario por su email
  // ===================================================================
  Future<bool> eliminarUsuario(String email) async {
    try {
      final url = Uri.parse('$apiBaseUrl/usuarios/$email');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        debugPrint('Usuario eliminado exitosamente.');
        return true;
      } else {
        debugPrint('Error del servidor [DELETE]: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error de conexión [DELETE]: $e');
      return false;
    }
  }
}