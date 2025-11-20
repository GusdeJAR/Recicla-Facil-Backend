import 'package:latlong2/latlong.dart';

class PuntoReciclaje {
  final String id;
  final String nombre;
  final String descripcion;
  final LatLng coordenadas;
  final String icono;
  final List<String> tipoMaterial;
  final String direccion;
  final String telefono;
  final String horario;
  final String aceptado;

  PuntoReciclaje({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.coordenadas,
    required this.icono,
    required this.tipoMaterial,
    required this.direccion,
    required this.telefono,
    required this.horario,
    required this.aceptado
  });

  factory PuntoReciclaje.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitud'] as num?)?.toDouble() ?? 21.5018; // Latitud por defecto
    final lon = (json['longitud'] as num?)?.toDouble() ?? -104.8946; // Longitud por defecto
    final List<dynamic> materialesDinamicos = json['tipo_material'] ?? [];
    return PuntoReciclaje(
      id: json["_id"],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
        coordenadas: LatLng(
        (json['latitud'] as num?)?.toDouble() ?? 0.0,
        (json['longitud'] as num?)?.toDouble() ?? 0.0
        ),
      icono: json['icono'],
      tipoMaterial: List<String>.from(materialesDinamicos),
      direccion: json['direccion'],
      telefono: json['telefono'],
      horario: json['horario'],
      aceptado: json['aceptado']
    );
  }
}