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


  static Future<List<dynamic>> obtenerPuntosReciclajePorMaterial(String material) async {
    final url = Uri.parse('$_apiRoot/puntos-reciclaje/material/'+material);
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
    final url = Uri.parse('$_apiRoot/puntos-reciclaje/estado/'+estado);
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
    final url = Uri.parse('$_apiRoot/puntos-reciclaje/estado/$puntoId');
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
    final url = Uri.parse('$_apiRoot/puntos-reciclaje/$puntoId');
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
    final url = Uri.parse('$_apiRoot/puntos-reciclaje/$puntoId');
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