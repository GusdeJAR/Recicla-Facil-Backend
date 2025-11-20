import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/contenido_educativo.dart';

class DetalleContenidoScreen extends StatelessWidget {
  final ContenidoEducativo contenido;

  const DetalleContenidoScreen({super.key, required this.contenido});

  // Método para obtener la URL completa y segura de la imagen
  String? _getImagenUrl(String? ruta) {
    if (ruta == null || ruta.isEmpty) return null;
    if (ruta.startsWith('http')) return ruta;

    const String serverBaseUrl = "http://192.168.137.115:3000"; //Cambiar IP
    return serverBaseUrl + ruta;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // --- 1. BARRA DE APLICACIÓN CON IMAGEN ---
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true, // La barra se queda visible al hacer scroll
            stretch: true, // La imagen se estira un poco al hacer overscroll
            backgroundColor: Colors.teal.shade800,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: _getImagenUrl(contenido.imagenPrincipal) ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 60,
                  ),
                ),
              ),
              stretchModes: const [StretchMode.zoomBackground],
            ),
          ),

          // --- 2. CUERPO DEL CONTENIDO ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Título y Descripción ---
                  Text(
                    contenido.titulo,
                    style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.0),
                  Text(
                    contenido.descripcion,
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[700], height: 1.5),
                  ),
                  SizedBox(height: 24.0),

                  // --- Chips de Categoría y Tipo de Material ---
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: [
                      _buildInfoChip(Icons.category_outlined, contenido.categoria, Colors.blue),
                      _buildInfoChip(Icons.inventory_2_outlined, contenido.tipoMaterial, Colors.teal),
                    ],
                  ),
                  SizedBox(height: 24.0),
                  Divider(),
                  SizedBox(height: 16.0),

                  // --- Contenido Principal ---
                  Text(
                    "Información Detallada",
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.0),
                  Text(
                    contenido.contenido,
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[800], height: 1.6),
                  ),
                  SizedBox(height: 24.0),

                  // --- Puntos Clave ---
                  _buildSectionList(
                    title: "Puntos Clave",
                    items: contenido.puntosClave,
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),

                  // --- Acciones Correctas ---
                  _buildSectionList(
                    title: "Qué Hacer (Acciones Correctas)",
                    items: contenido.accionesCorrectas,
                    icon: Icons.thumb_up_outlined,
                    color: Colors.blue,
                  ),

                  // --- Acciones Incorrectas ---
                  _buildSectionList(
                    title: "Qué Evitar (Acciones Incorrectas)",
                    items: contenido.accionesIncorrectas,
                    icon: Icons.thumb_down_outlined,
                    color: Colors.red,
                  ),

                  // --- Galería de Imágenes (si hay más de una) ---
                  if (contenido.imagenes.length > 1) ...[
                    SizedBox(height: 24.0),
                    Text(
                      "Galería",
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12.0),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: contenido.imagenes.length,
                        itemBuilder: (context, index) {
                          final imagen = contenido.imagenes[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: _getImagenUrl(imagen.ruta) ?? '',
                              width: 200,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para crear las secciones de listas (Puntos Clave, etc.)
  Widget _buildSectionList({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    if (items.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.0),
          ...items.map((item) => ListTile(
            leading: Icon(icon, color: color),
            title: Text(item, style: TextStyle(fontSize: 16.0, color: Colors.grey[800])),
          )),
        ],
      ),
    );
  }

  // Widget auxiliar para crear los chips de información
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    final Color textColor = hslColor.withLightness((hslColor.lightness - 0.3).clamp(0.0, 1.0)).toColor();

    final Color backgroundColor = color.withOpacity(0.1);

    final Color borderColor = color.withOpacity(0.2);
    return Chip(
      avatar: Icon(icon, color: textColor, size: 20),
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      side: BorderSide(color: borderColor),
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}
