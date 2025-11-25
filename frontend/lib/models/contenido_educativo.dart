class ImagenContenido {
  final String ruta;
  final String public_id;
  final String pieDeImagen;
  final bool esPrincipal;

  ImagenContenido({
    required this.ruta,
    required this.public_id,
    required this.pieDeImagen,
    required this.esPrincipal,
  });

  factory ImagenContenido.fromJson(Map<String, dynamic> json) {
    return ImagenContenido(
      ruta: json['ruta'] ?? '',
      public_id: json['public_id'] ?? '',
      pieDeImagen: json['pie_de_imagen'] ?? '',
      esPrincipal: json['es_principal'] ?? false,
    );
  }
}

class ContenidoEducativo {
  final String id;
  final String titulo;
  final String descripcion;
  final String contenido;
  final String categoria;
  final String tipoMaterial;
  final List<ImagenContenido> imagenes;
  final List<String> puntosClave;
  final List<String> accionesCorrectas;
  final List<String> accionesIncorrectas;
  final List<String> etiquetas;
  final bool publicado;
  final String autor;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  ContenidoEducativo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.contenido,
    required this.categoria,
    required this.tipoMaterial,
    required this.imagenes,
    required this.puntosClave,
    required this.accionesCorrectas,
    required this.accionesIncorrectas,
    required this.etiquetas,
    required this.publicado,
    required this.autor,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory ContenidoEducativo.fromJson(Map<String, dynamic> json) {
    return ContenidoEducativo(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      contenido: json['contenido'] ?? '',
      categoria: json['categoria'] ?? '',
      tipoMaterial: json['tipo_material'] ?? '',
      imagenes: (json['imagenes'] as List? ?? [])
          .map((img) => ImagenContenido.fromJson(img))
          .toList(),
      puntosClave: List<String>.from(json['puntos_clave'] ?? []),
      accionesCorrectas: List<String>.from(json['acciones_correctas'] ?? []),
      accionesIncorrectas: List<String>.from(json['acciones_incorrectas'] ?? []),
      etiquetas: List<String>.from(json['etiquetas'] ?? []),
      publicado: json['publicado'] ?? false,
      autor: json['autor'] ?? '',
      fechaCreacion: DateTime.parse(json['fecha_creacion'] ?? DateTime.now().toIso8601String()),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Método para obtener la imagen principal
  String? get imagenPrincipal {
    final principal = imagenes.firstWhere(
      (img) => img.esPrincipal == true,
      orElse: () => imagenes.isNotEmpty ? imagenes.first : ImagenContenido(ruta: '', public_id: '', pieDeImagen: '', esPrincipal: false),
    );
    return principal.ruta.isNotEmpty ? principal.ruta : null;
  }
}