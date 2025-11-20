// En: models/queja_model.dart

import 'dart:convert';

// Función auxiliar para decodificar una lista de Quejas desde un string JSON
List<Queja> quejaFromJson(String str) => List<Queja>.from(json.decode(str).map((x) => Queja.fromJson(x)));

class Queja {
  // --- ATRIBUTOS ---
  // El 'id' es el _id que genera MongoDB. Es crucial.
  final String id;
  final String correo;
  final String categoria;
  final String mensaje;
  final String estado;
  final DateTime fechaCreacion;
  // Estos pueden ser nulos, por eso usamos '?'
  final String? respuestaAdmin;
  final DateTime? fechaAtencion;

  // --- CONSTRUCTOR ---
  Queja({
    required this.id,
    required this.correo,
    required this.categoria,
    required this.mensaje,
    required this.estado,
    required this.fechaCreacion,
    this.respuestaAdmin,
    this.fechaAtencion,
  });

  // --- MÉTODO 'fromJson' (El más importante) ---
  // Este "constructor de fábrica" crea una instancia de Queja
  // a partir del mapa JSON que viene de tu API.
  factory Queja.fromJson(Map<String, dynamic> json) => Queja(
    // MongoDB devuelve el id como '_id'. Lo mapeamos a nuestro campo 'id'.
    id: json["_id"],
    correo: json["correo"],
    categoria: json["categoria"],
    mensaje: json["mensaje"],
    estado: json["estado"],
    // El JSON envía fechas como strings. DateTime.parse() las convierte a objetos DateTime.
    fechaCreacion: DateTime.parse(json["fechaCreacion"]),
    respuestaAdmin: json["respuestaAdmin"],
    // Si la fecha de atención existe en el JSON, la convertimos. Si no, es null.
    fechaAtencion: json["fechaAtencion"] == null ? null : DateTime.parse(json["fechaAtencion"]),
  );
}
