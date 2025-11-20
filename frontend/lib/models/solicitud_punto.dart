// models/solicitud_punto.dart
class SolicitudPunto {
  final String id;
  final String nombre;
  final String descripcion;
  final Direccion direccion;
  final List<String> tipoMaterial;
  final String telefono;
  final String horario;
  final String usuarioSolicitante;
  final String? adminRevisor;
  final String estado;
  final String? comentariosAdmin;
  final DateTime fechaCreacion;
  final DateTime? fechaRevision;

  SolicitudPunto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.tipoMaterial,
    required this.telefono,
    required this.horario,
    required this.usuarioSolicitante,
    this.adminRevisor,
    required this.estado,
    this.comentariosAdmin,
    required this.fechaCreacion,
    this.fechaRevision,
  });

  factory SolicitudPunto.fromJson(Map<String, dynamic> json) {
    return SolicitudPunto(
      id: json['_id'] ?? json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      direccion: Direccion.fromJson(json['direccion']),
      tipoMaterial: List<String>.from(json['tipo_material']),
      telefono: json['telefono'],
      horario: json['horario'],
      usuarioSolicitante: json['usuarioSolicitante'] is String 
          ? json['usuarioSolicitante'] 
          : json['usuarioSolicitante']['_id'],
      adminRevisor: json['adminRevisor'] is String 
          ? json['adminRevisor'] 
          : json['adminRevisor']?['_id'],
      estado: json['estado'],
      comentariosAdmin: json['comentariosAdmin'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaRevision: json['fechaRevision'] != null 
          ? DateTime.parse(json['fechaRevision']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion.toJson(),
      'tipo_material': tipoMaterial,
      'telefono': telefono,
      'horario': horario,
    };
  }
}

class Direccion {
  final String calle;
  final String numero;
  final String colonia;
  final String ciudad;
  final String estado;
  final String pais;

  Direccion({
    required this.calle,
    required this.numero,
    required this.colonia,
    this.ciudad = 'Tepic',
    this.estado = 'Nayarit',
    this.pais = 'México',
  });

  factory Direccion.fromJson(Map<String, dynamic> json) {
    return Direccion(
      calle: json['calle'],
      numero: json['numero'],
      colonia: json['colonia'],
      ciudad: json['ciudad'] ?? 'Tepic',
      estado: json['estado'] ?? 'Nayarit',
      pais: json['pais'] ?? 'México',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calle': calle,
      'numero': numero,
      'colonia': colonia,
      'ciudad': ciudad,
      'estado': estado,
      'pais': pais,
    };
  }
}