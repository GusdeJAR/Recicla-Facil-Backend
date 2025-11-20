import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/contenido_educativo.dart';

class ContenidoEduService {
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

  static String get serverBaseUrl {
    if (kReleaseMode) {
      return '';
    }

    // EN DESARROLLO LOCAL:
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    // Dispositivo físico (iOS/Android):
    return 'http://$_direccionIpLocal:3000';
  }
  // ===================================================================
  // 1. OBTENER TODO EL CONTENIDO EDUCATIVO
  // ===================================================================
  Future<List<ContenidoEducativo>> obtenerContenidoEducativo({
    String? categoria,
    String? tipoMaterial,
    bool publicado = true,
    String? etiqueta,
    int limit = 10,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_apiRoot/contenido-educativo/');
    debugPrint('ContenidoEduService - Obteniendo contenido en: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> contenidosJson = data['contenidos'];
        return contenidosJson.map((json) => ContenidoEducativo.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar contenido educativo: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // ===================================================================
  // 2. OBTENER CONTENIDO POR ID
  // ===================================================================
  Future<ContenidoEducativo> obtenerContenidoPorId(String id) async {
    final url = Uri.parse('$_apiRoot/contenido-educativo/'+id);
    debugPrint('ContenidoEduService - Obteniendo contenido por ID en: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ContenidoEducativo.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Contenido no encontrado');
      } else {
        throw Exception('Error al cargar el contenido: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // ===================================================================
  // 3. CREAR CONTENIDO EDUCATIVO
  // ===================================================================
  Future<Map<String, dynamic>> crearContenidoEducativo({
    required String titulo,
    required String descripcion,
    required String contenido,
    required String categoria,
    required String tipoMaterial,
    required List<dynamic> imagenes, // Dinámico para soportar File (móvil) y File web
    required List<String> puntosClave,
    required List<String> accionesCorrectas,
    required List<String> accionesIncorrectas,
    required List<String> etiquetas,
    bool publicado = false,
    required int imgPrincipal,
  }) async {
    final url = Uri.parse('$_apiRoot/contenido-educativo/');
    debugPrint('ContenidoEduService - Subiendo contenido a: $url');

    // Crear solicitud multipart
    final request = http.MultipartRequest('POST', url);

    // ===== CAMPOS DE TEXTO =====
    request.fields['titulo'] = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['contenido'] = contenido;
    request.fields['categoria'] = categoria;
    request.fields['tipo_material'] = tipoMaterial;
    request.fields['publicado'] = publicado.toString();

    // Listas codificadas como JSON string
    request.fields['puntos_clave'] = jsonEncode(puntosClave);
    request.fields['acciones_correctas'] = jsonEncode(accionesCorrectas);
    request.fields['acciones_incorrectas'] = jsonEncode(accionesIncorrectas);
    request.fields['etiquetas'] = jsonEncode(etiquetas);
    request.fields['img_principal'] = imgPrincipal.toString();



    // ===== ARCHIVOS =====
    for (var i = 0; i < imagenes.length; i++) {
      final file = imagenes[i];

      // En web, usar bytes; en móvil, usar fromPath
      if (kIsWeb) {
        // Para web, leer los bytes del archivo
        final bytes = await file.readAsBytes();

        // Intentar obtener mime type desde los bytes
        String? mimeType = lookupMimeType('', headerBytes: bytes);
        // Derivar extensión segura si el nombre no la contiene
        String filename = '';
  if (file is XFile) filename = file.name;
        if (filename.isEmpty) {
          final ext = (mimeType != null && mimeType.contains('/')) ? mimeType.split('/').last : 'jpg';
          filename = 'imagen_$i.$ext';
        }

        MediaType? mediaType;
        if (mimeType != null && mimeType.contains('/')) {
          final parts = mimeType.split('/');
          mediaType = MediaType(parts[0], parts[1]);
        }

        final multipartFile = http.MultipartFile.fromBytes(
          'imagenes',
          bytes,
          filename: filename,
          contentType: mediaType,
        );
        request.files.add(multipartFile);
      } else {
        // Para móvil, usar fromPath
        final multipartFile = await http.MultipartFile.fromPath(
          'imagenes',
          file.path,
        );
        request.files.add(multipartFile);
      }
    }

    try {
      // Enviar la solicitud con timeout
      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      // Loguear status y body para facilitar debugging
      debugPrint('ContenidoEduService - upload status: ${response.statusCode}');
      debugPrint('ContenidoEduService - upload body: ${response.body}');

      // Intentar parsear JSON solo si el servidor devolvió un 2xx
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          data['statusCode'] = response.statusCode;
          return data;
        } catch (e) {
          // Respuesta 2xx pero no es JSON
          return {
            'statusCode': response.statusCode,
            'body': response.body,
          };
        }
      }

      // En caso de error (4xx/5xx) intentar extraer mensaje JSON, si no, devolver body crudo
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        errorData['statusCode'] = response.statusCode;
        throw Exception('Error al subir contenido: ${response.statusCode} - ${errorData}');
      } catch (_) {
        throw Exception('Error al subir contenido: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      // Añadir más contexto al error para facilitar debugging en la app
      throw Exception('Error al subir contenido: ${e.toString()}');
    }
  }

  // ===================================================================
  // 4. ACTUALIZAR CONTENIDO EDUCATIVO (CON LÓGICA MULTIPART)
  // ===================================================================
  Future<Map<String, dynamic>> actualizarContenidoEducativo({
    required String id,
    String? titulo,
    String? descripcion,
    String? contenido,
    String? categoria,
    String? tipoMaterial,
    List<String>? puntosClave,
    List<String>? accionesCorrectas,
    List<String>? accionesIncorrectas,
    List<String>? etiquetas,
    bool? publicado,
    int? imgPrincipal,
    required List<dynamic> nuevasImagenes, // Dinámico para soportar File (móvil) y File web
    List<String>? idsImagenesAEliminar,
  }) async {
    final url = Uri.parse('$_apiRoot/contenido-educativo/$id');
    debugPrint('ContenidoEduService - Actualizando contenido (multipart) en: $url');

    // Crear solicitud multipart, usando PUT para actualización
    final request = http.MultipartRequest('PUT', url);

    // ===== CAMPOS DE TEXTO (SOLO SI NO SON NULOS) =====
    if (titulo != null) request.fields['titulo'] = titulo;
    if (descripcion != null) request.fields['descripcion'] = descripcion;
    if (contenido != null) request.fields['contenido'] = contenido;
    if (categoria != null) request.fields['categoria'] = categoria;
    if (tipoMaterial != null) request.fields['tipo_material'] = tipoMaterial;
    if (publicado != null) request.fields['publicado'] = publicado.toString();
    if (imgPrincipal != null) request.fields['img_principal'] = imgPrincipal.toString();

    // ===== LISTAS (CODIFICADAS COMO JSON) =====
    if (puntosClave != null) request.fields['puntos_clave'] = jsonEncode(puntosClave);
    if (accionesCorrectas != null) request.fields['acciones_correctas'] = jsonEncode(accionesCorrectas);
    if (accionesIncorrectas != null) request.fields['acciones_incorrectas'] = jsonEncode(accionesIncorrectas);
    if (etiquetas != null) request.fields['etiquetas'] = jsonEncode(etiquetas);
    if (idsImagenesAEliminar != null) request.fields['ids_imagenes_a_eliminar'] = jsonEncode(idsImagenesAEliminar);

    // ===== NUEVOS ARCHIVOS DE IMAGEN =====
    var idx = 0;
    for (var file in nuevasImagenes) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        String? mimeType = lookupMimeType('', headerBytes: bytes);
        String filename = '';
  if (file is XFile) filename = file.name;
        if (filename.isEmpty) {
          final ext = (mimeType != null && mimeType.contains('/')) ? mimeType.split('/').last : 'jpg';
          filename = 'imagen_$idx.$ext';
        }

        MediaType? mediaType;
        if (mimeType != null && mimeType.contains('/')) {
          final parts = mimeType.split('/');
          mediaType = MediaType(parts[0], parts[1]);
        }

        final multipartFile = http.MultipartFile.fromBytes(
          'imagenes',
          bytes,
          filename: filename,
          contentType: mediaType,
        );
        request.files.add(multipartFile);
      } else {
        final multipartFile = await http.MultipartFile.fromPath(
          'imagenes',
          file.path,
        );
        request.files.add(multipartFile);
      }
      idx++;
    }

    try {
      // Enviar la solicitud
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      // Loguear para depuración
      debugPrint('ContenidoEduService - update status: ${response.statusCode}');
      debugPrint('ContenidoEduService - update body: ${response.body}');

      // Manejar la respuesta, similar al método de creación
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          data['statusCode'] = response.statusCode;
          return data;
        } catch (e) {
          return {'statusCode': response.statusCode, 'body': response.body};
        }
      }

      // En caso de error, intentar extraer el mensaje
      try {
        final Map<String, dynamic> errorData = json.decode(response.body);
        errorData['statusCode'] = response.statusCode;
        throw Exception('Error al actualizar contenido: ${response.statusCode} - ${errorData}');
      } catch (_) {
        throw Exception('Error al actualizar contenido: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al actualizar. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Error al actualizar contenido: ${e.toString()}');
    }
  }


  // ===================================================================
  // 5. ELIMINAR CONTENIDO EDUCATIVO
  // ===================================================================
  Future<Map<String, dynamic>> eliminarContenidoEducativo(String id) async {
    final url = Uri.parse('$_apiRoot/contenido-educativo/'+id);
    debugPrint('ContenidoEduService - Eliminando contenido en: $url');

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
      throw Exception('Ocurrió un error inesperado al eliminar el contenido: $e');
    }
  }

  // ===================================================================
  // 6. OBTENER CONTENIDO POR CATEGORÍA
  // ===================================================================
  Future<List<ContenidoEducativo>> obtenerContenidoPorCategoria(String categoria, {bool publicado = true}) async {
    final uri = Uri.parse('$_apiRoot/contenido-educativo/categoria/'+categoria);
    debugPrint('ContenidoEduService - Obteniendo contenido por categoría en: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContenidoEducativo.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar contenido por categoría: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // ===================================================================
  // 7. OBTENER CONTENIDO POR TIPO DE MATERIAL
  // ===================================================================
  Future<List<ContenidoEducativo>> obtenerContenidoPorTipoMaterial(String tipoMaterial, {bool publicado = true}) async {
    final uri = Uri.parse('$_apiRoot/contenido-educativo/material/'+tipoMaterial);
    debugPrint('ContenidoEduService - Obteniendo contenido por tipo de material en: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContenidoEducativo.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar contenido por tipo de material: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  // ===================================================================
  // 8. BUSCAR CONTENIDO EDUCATIVO
  // ===================================================================
  Future<List<ContenidoEducativo>> buscarContenidoEducativo(String termino, {bool publicado = true}) async {
    final uri = Uri.parse('$_apiRoot/contenido-educativo/buscar/'+termino);
    debugPrint('ContenidoEduService - Buscando contenido en: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContenidoEducativo.fromJson(json)).toList();
      } else {
        throw Exception('Error al buscar contenido: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Revisa tu conexión.');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }
}