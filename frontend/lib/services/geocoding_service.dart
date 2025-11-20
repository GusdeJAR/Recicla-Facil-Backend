// lib/services/geocoding_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UbicacionPreview {
  final double latitud;
  final double longitud;
  final String? precision;

  UbicacionPreview({
    required this.latitud,
    required this.longitud,
    this.precision,
  });

  factory UbicacionPreview.fromJson(Map<String, dynamic> json) {
    return UbicacionPreview(
      latitud: json['latitud'] is int 
          ? (json['latitud'] as int).toDouble() 
          : json['latitud'],
      longitud: json['longitud'] is int 
          ? (json['longitud'] as int).toDouble() 
          : json['longitud'],
      precision: json['precision'],
    );
  }
}

class DireccionDesdeCoordenas {
  final String? calle;
  final String? numero;
  final String? colonia;
  final String? ciudad;
  final String? estado;
  final String direccion;

  DireccionDesdeCoordenas({
    required this.calle,
    required this.numero,
    required this.colonia,
    required this.ciudad,
    required this.estado,
    required this.direccion,
  });

  factory DireccionDesdeCoordenas.fromJson(Map<String, dynamic> json) {
    return DireccionDesdeCoordenas(
      calle: json['calle'],
      numero: json['numero'],
      colonia: json['colonia'],
      ciudad: json['ciudad'],
      estado: json['estado'],
      direccion: json['direccion'] ?? '',
    );
  }
}

class GeocodingService {
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
  // Cache local para reverse geocoding: key = hash(lat,lon), value = {result, timestamp}
  final Map<String, Map<String, dynamic>> _reverseCache = {};
  static const Duration _reverseCacheTtl = Duration(hours: 48);

  String _hashCoords(double lat, double lon) {
    final latR = (lat * 100000).round();
    final lonR = (lon * 100000).round();
    return '$latR|$lonR';
  }
  /// Obtiene las coordenadas de una dirección para vista previa
  /// No requiere autenticación (endpoint público)
  Future<UbicacionPreview> obtenerUbicacionPreview({
    required String calle,
    required String numero,
    required String colonia,
    String ciudad = 'Tepic',
    String estado = 'Nayarit',
    String pais = 'Mexico',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/geocodificar-preview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'calle': calle.trim(),
          'numero': numero.trim(),
          'colonia': colonia.trim(),
          'ciudad': ciudad,
          'estado': estado,
          'pais': pais,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UbicacionPreview.fromJson(data['data']);
      } else {
        throw Exception('Error al geocodificar: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerUbicacionPreview: $e');
      // Devolver Tepic como fallback
      return UbicacionPreview(
        latitud: 21.5018,
        longitud: -104.8946,
        precision: 'por defecto',
      );
    }
  }

  /// Obtiene la dirección desde coordenadas (reverse geocoding)
  /// Actualiza la ubicación cuando el usuario ajusta el marcador en el mapa
  Future<DireccionDesdeCoordenas> obtenerDireccionDesdeCoordenas({
    required double latitud,
    required double longitud,
  }) async {
    final key = _hashCoords(latitud, longitud);
    // Return from cache if available and fresh
    final cached = _reverseCache[key];
    if (cached != null) {
      final ts = cached['ts'] as DateTime;
      if (DateTime.now().difference(ts) <= _reverseCacheTtl) {
        try {
          return DireccionDesdeCoordenas.fromJson(Map<String, dynamic>.from(cached['data']));
        } catch (_) {}
      } else {
        _reverseCache.remove(key);
      }
    }

    try {
      print('GeocodingService: Llamando a reverse-geocode para Lat: $latitud, Lon: $longitud');
      final future = http.post(
        Uri.parse('$apiBaseUrl/api/reverse-geocode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud,
        }),
      );

      // Evitar esperas largas: timeout de 5s
      final response = await future.timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('GeocodingService: Respuesta exitosa: ${data['data']}');

        // Parse inicial
        final raw = Map<String, dynamic>.from(data['data'] ?? {});
        DireccionDesdeCoordenas resultado = DireccionDesdeCoordenas.fromJson(raw);

        // Si no viene número, intentar extraerlo desde el campo 'direccion' (display_name)
        final numeroActual = (resultado.numero ?? '').toString().trim();
        if (numeroActual.isEmpty) {
          final display = (raw['direccion'] ?? raw['displayName'] ?? '').toString();
          // Patrones comunes: "No. 123", "#123", "Número 123" o primer token numérico
          final pat1 = RegExp(r'(?:No\.?|Número|Numero|Num|Nº|#)\s*([0-9A-Za-z\-]+)', caseSensitive: false);
          final m1 = pat1.firstMatch(display);
          String? numeroExtra;
          if (m1 != null) {
            numeroExtra = m1.group(1);
          } else {
            final pat2 = RegExp(r'\b(\d{1,6}[A-Za-z\-]?)\b');
            final m2 = pat2.firstMatch(display);
            if (m2 != null) numeroExtra = m2.group(1);
          }

          if (numeroExtra != null && numeroExtra.trim().isNotEmpty) {
            // Reconstruir el objeto con el número extraído
            resultado = DireccionDesdeCoordenas(
              calle: resultado.calle,
              numero: numeroExtra,
              colonia: resultado.colonia,
              ciudad: resultado.ciudad,
              estado: resultado.estado,
              direccion: resultado.direccion,
            );
            // Actualizar raw para cache
            try {
              raw['numero'] = numeroExtra;
            } catch (_) {}
            print('GeocodingService: Número extraído desde display_name: $numeroExtra');
          }
        }

        // Guardar en cache (raw map)
        try {
          _reverseCache[key] = {'data': Map<String, dynamic>.from(raw), 'ts': DateTime.now()};
        } catch (_) {}

        print('GeocodingService: Dirección parseada - Calle: ${resultado.calle}, Colonia: ${resultado.colonia}, Numero: ${resultado.numero}');
        return resultado;
      } else {
        print('GeocodingService: Error HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Error en reverse geocoding: ${response.statusCode}');
      }
    } catch (e) {
      print('GeocodingService: Error en obtenerDireccionDesdeCoordenas: $e');
      // Devolver una dirección vacía como fallback
      return DireccionDesdeCoordenas(
        calle: null,
        numero: null,
        colonia: null,
        ciudad: null,
        estado: null,
        direccion: 'No se pudo obtener la dirección',
      );
    }
  }
}
