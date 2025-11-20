import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

class UsuarioService {

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
  // 1. LOGIN de un usuario
  // ===================================================================
  Future<Map<String, dynamic>> loginUsuario({
    required String nombre,
    required String password,
  }) async {
    final url = Uri.parse('$_apiRoot/usuarios/login');
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
    final url = Uri.parse('$_apiRoot/usuarios');
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
    final url = Uri.parse('$_apiRoot/usuarios');
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
    final url = Uri.parse('$_apiRoot/usuarios/$email');
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
      final url = Uri.parse('$_apiRoot/usuarios/$email');
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