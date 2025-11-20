import '../models/punto_reciclaje.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/foundation.dart';

class PuntosReciclajeService {
  // ===================================================================
  // DETECTAR IP AUTOMÁTICAMENTE
  // ===================================================================

  // --- URLs de desarrollo ---
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

  static Future<List<dynamic>> obtenerPuntosReciclajePorMaterial(String material) async {
    final url = Uri.parse('$apiBaseUrl/api/puntos-reciclaje/material/'+material);
    debugPrint('Puntos_reciclaje_service - Obteniendo datos en: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final dynamic datosDecodificados = json.decode(response.body);

        if (datosDecodificados is List) {
          debugPrint('Puntos_reciclaje_service - Éxito. Se recibieron ${datosDecodificados.length} elementos.');
          return datosDecodificados;
        } else {
          debugPrint('Puntos_reciclaje_service - Error: La respuesta no es una lista, es un ${datosDecodificados.runtimeType}.');
          return [];
        }
      } else {
        debugPrint('Puntos_reciclaje_service - Error del servidor. Código: ${response.statusCode}. Cuerpo: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Puntos_reciclaje_service - Excepción capturada: $e');
      return [];
    }
  }

  static Future<List<dynamic>> obtenerPuntosReciclajeEstado(String estado) async {
    final url = Uri.parse('$apiBaseUrl/api/puntos-reciclaje/estado/'+estado);
    debugPrint('Puntos_reciclaje_service - Obteniendo datos en: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final dynamic datosDecodificados = json.decode(response.body);

        if (datosDecodificados is List) {
          debugPrint('Puntos_reciclaje_service - Éxito. Se recibieron ${datosDecodificados.length} elementos.');
          return datosDecodificados;
        } else {
          debugPrint('Puntos_reciclaje_service - Error: La respuesta no es una lista, es un ${datosDecodificados.runtimeType}.');
          return [];
        }
      } else {
        debugPrint('Puntos_reciclaje_service - Error del servidor. Código: ${response.statusCode}. Cuerpo: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Puntos_reciclaje_service - Excepción capturada: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> aceptarPunto(String puntoId) async {
    final url = Uri.parse('$apiBaseUrl/api/puntos-reciclaje/estado/$puntoId');
    debugPrint('Puntos_reciclaje_service - Aceptando punto en: $url');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseData = json.decode(response.body);
      responseData['statusCode'] = response.statusCode;
      return responseData;

    } on TimeoutException {
      throw Exception('Puntos_reciclaje_service - Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Puntos_reciclaje_service - Ocurrió un error inesperado al aceptar la queja: $e');
    }
  }

  static Future<bool> actualizarPuntoReciclaje({
    required String puntoId,
    String? nombre,
    String? descripcion,
    double? latitud,
    double? longitud,
    String? icono,
    List<String>? tipo_material,
    String? direccion,
    String? telefono,
    String? horario,
    String? aceptado
  }) async {
    final url = Uri.parse('$apiBaseUrl/api/puntos-reciclaje/$puntoId');
    final Map<String, dynamic> body = {

    };
    if (nombre != null) body['nombre'] = nombre;
    if (descripcion != null) body['descripcion'] = descripcion;
    if (latitud != null) body['latitud'] = latitud;
    if (longitud != null) body['longitud'] = longitud;
    if (icono != null) body['icono'] = icono;
    if (tipo_material != null) body['tipo_material'] = tipo_material;
    if (direccion != null) body['direccion'] = direccion;
    if (telefono != null) body['telefono'] = telefono;
    if (horario != null) body['horario'] = horario;
    if (aceptado != null) body['aceptado'] = aceptado;
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
        debugPrint('Puntos_reciclaje_service - Punto actualizado exitosamente.');
        return true;
      } else {
        debugPrint('Puntos_reciclaje_service - Error del servidor [PUT]: ${response.statusCode}');
        debugPrint('Puntos_reciclaje_service - Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Puntos_reciclaje_service - Error de conexión [PUT]: $e');
      return false;
    }
  }

  static Future<bool> eliminarPuntoReciclaje(String puntoId) async {
    final url = Uri.parse('$apiBaseUrl/api/puntos-reciclaje/$puntoId');
    debugPrint('Puntos_reciclaje_service - Eliminando punto en: $url');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint("Puntos_reciclaje_service - Punto eliminado exitosamente.");
        return true;
      } else {
        debugPrint('Puntos_reciclaje_service - Error del servidor [DELETE]: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Puntos_reciclaje_service - Error de conexión [DELETE]: $e');
      return false;
    }
  }
}