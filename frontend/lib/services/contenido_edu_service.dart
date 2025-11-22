import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cloudinary_image.dart';
import '../models/contenido_educativo.dart';

class ContenidoEduService {
  static String apiBaseUrl = 'https://recicla-facil-backend.vercel.app';


  static Future<CloudinaryImage> subirImagen(XFile imagen) async {
    // 1. Define tus credenciales y preset (ESTO NO DEBE IR EN UN ENTORNO DE PRODUCCIÓN,
    // USA VARIABLES DE ENTORNO O EL SDK DE CLOUDINARY PARA GESTIONAR ESTO)
    const String CLOUD_NAME = 'dugacfyo1';
    const String UPLOAD_PRESET = 'subida-movil';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$CLOUD_NAME/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = UPLOAD_PRESET;
    if (kIsWeb) {
      // 🌐 WEB: Leemos los bytes directamente
      final fileBytes = await imagen.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Clave requerida por Cloudinary
          fileBytes,
          filename: imagen.name, // Usamos el nombre del archivo
        ),
      );
    } else {
      // 📱 MÓVIL/DESKTOP: Usamos la ruta (donde dart:io está disponible)
      final path = imagen.path;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          path,
          filename: imagen.name,
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Fallo en la subida a Cloudinary: ${response.body}');
      }

      final Map<String, dynamic> data = json.decode(response.body);

      return CloudinaryImage(
        ruta: data['secure_url'],
        publicId: data['public_id'],
      );
    } catch (e) {
      debugPrint('Error en la subida a Cloudinary: $e');
      throw Exception('Error al subir la imagen.');
    }
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
    final uri = Uri.parse('$apiBaseUrl/api/contenido-educativo');
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
    final url = Uri.parse('$apiBaseUrl/api/contenido-educativo/'+id);
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

    // 🆕 Cambiado de List<XFile> a String JSON
    required String imagenesPreSubidas,

    required List<String> puntosClave,
    required List<String> accionesCorrectas,
    required List<String> accionesIncorrectas,
    required List<String> etiquetas,
    required bool publicado,
    required int imgPrincipal,
  }) async {

    final uri = Uri.parse('$apiBaseUrl/api/contenido-educativo/');

    // 1. Preparamos el cuerpo de la solicitud como un mapa de Strings
    final body = {
      'titulo': titulo,
      'descripcion': descripcion,
      'contenido': contenido,
      'categoria': categoria,
      'tipo_material': tipoMaterial,

      // 2. Enviamos el String JSON de imágenes
      'imagenes_pre_subidas': imagenesPreSubidas,

      // 3. El backend espera todos los arrays como Strings JSON
      'puntos_clave': json.encode(puntosClave),
      'acciones_correctas': json.encode(accionesCorrectas),
      'acciones_incorrectas': json.encode(accionesIncorrectas),
      'etiquetas': json.encode(etiquetas),

      // 4. Enviamos booleanos/números como Strings
      'publicado': publicado.toString(),
      'img_principal': imgPrincipal.toString(),
    };

    try {
      // Usaremos http.post y content-type application/json o x-www-form-urlencoded
      // Si tu backend usa body-parser con x-www-form-urlencoded, usa http.post
      final response = await http.post(
        uri,
        // Usamos codificación JSON ya que estamos enviando un cuerpo estructurado
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'statusCode': 201, 'contenido': responseBody.containsKey('contenido') ? responseBody['contenido'] : null};
      } else {
        return {'statusCode': response.statusCode, 'mensaje': responseBody['mensaje'] ?? 'Error al crear contenido'};
      }

    } catch (e) {
      return {'statusCode': 500, 'mensaje': 'Error de conexión: $e'};
    }
  }

  // ===================================================================
  // 4. ACTUALIZAR CONTENIDO EDUCATIVO (CON LÓGICA MULTIPART)
  // ===================================================================
  Future<Map<String, dynamic>> actualizarContenidoEducativo({
    required String id,
    required String titulo,
    required String descripcion,
    required String contenido,
    required String categoria,
    required String tipoMaterial,
    required List<String> puntosClave,
    required List<String> etiquetas,

    // 🆕 Parámetros para la nueva lógica de imágenes
    String? imagenesAnadidasPreSubidas, // String JSON de las NUEVAS URLs/IDs
    List<String>? idsImagenesAEliminar, // Lista de public_id a borrar
    String? imgPrincipalRuta,           // URL de la imagen que DEBE ser la principal
    bool? publicado, // Si se gestiona la publicación en la edición

  }) async {

    final uri = Uri.parse('$apiBaseUrl/api/contenido-educativo/$id');

    // 1. Preparamos el cuerpo de la solicitud (body)
    final Map<String, dynamic> body = {
      'titulo': titulo,
      'descripcion': descripcion,
      'contenido': contenido,
      'categoria': categoria,
      'tipo_material': tipoMaterial,

      // Enviamos arrays como Strings JSON
      'puntos_clave': json.encode(puntosClave),
      'etiquetas': json.encode(etiquetas),

      // 2. Parámetros de la Lógica de Imágenes

      // IDs a borrar: El backend los usa para eliminar de Cloudinary y filtrar de la BD
      if (idsImagenesAEliminar != null && idsImagenesAEliminar.isNotEmpty)
        'ids_imagenes_a_eliminar': json.encode(idsImagenesAEliminar),

      // Nuevas imágenes: El backend las usa para añadir al array de la BD
      if (imagenesAnadidasPreSubidas != null)
        'imagenes_a_agregar_pre_subidas': imagenesAnadidasPreSubidas,

      // Ruta de la imagen principal: El backend la usa para actualizar el flag es_principal
      if (imgPrincipalRuta != null)
        'img_principal_ruta': imgPrincipalRuta,

      // Estado de publicación (si aplica)
      if (publicado != null)
        'publicado': publicado.toString(),
    };

    try {
      // 3. Ejecución de la solicitud HTTP (PUT)
      final response = await http.put(
        uri,
        // Usamos content-type application/json ya que no enviamos archivos, solo texto y JSON string
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'statusCode': 200, 'contenido': responseBody.containsKey('contenido') ? responseBody['contenido'] : null};
      } else {
        // En caso de fallo, devolvemos el código y el mensaje de error del backend
        return {'statusCode': response.statusCode, 'mensaje': responseBody['mensaje'] ?? 'Error al actualizar contenido'};
      }

    } catch (e) {
      // Error de red o parseo
      return {'statusCode': 500, 'mensaje': 'Error de conexión o fallo al procesar la respuesta: ${e.toString()}'};
    }
  }


  // ===================================================================
  // 5. ELIMINAR CONTENIDO EDUCATIVO
  // ===================================================================
  Future<Map<String, dynamic>> eliminarContenidoEducativo(String id) async {
    final url = Uri.parse('$apiBaseUrl/api/contenido-educativo/'+id);
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
    final uri = Uri.parse('$apiBaseUrl/api/contenido-educativo/categoria/'+categoria);
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
    final uri = Uri.parse('$apiBaseUrl/api/contenido-educativo/material/'+tipoMaterial);
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
    final uri = Uri.parse('$apiBaseUrl/api/contenido-educativo/buscar/'+termino);
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