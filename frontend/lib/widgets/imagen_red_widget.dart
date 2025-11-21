import 'package:flutter/material.dart';
// Asegúrate de que esta ruta de importación sea la correcta para tu proyecto
import '../services/contenido_edu_service.dart';

/// Widget mejorado para cargar imágenes de red de forma robusta en cualquier dispositivo.
/// Construye la URL de la imagen de forma síncrona, eliminando la necesidad de FutureBuilder.
class ImagenRedWidget extends StatelessWidget {
  final String? rutaOUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool mostrarLoadingWidget;

  const ImagenRedWidget({
    super.key,
    required this.rutaOUrl,
    this.height = 200,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.mostrarLoadingWidget = true,
  });

  @override
  Widget build(BuildContext context) {
    // --- PASO 1: Validar si la ruta de la imagen es válida ---
    if (rutaOUrl == null || rutaOUrl!.isEmpty) {
      return _buildPlaceholder('Sin imagen');
    }

    // --- PASO 2: Construir la URL final de forma SÍNCRONA ---
    String urlFinal;
    if (rutaOUrl!.startsWith('http')) {
      // Si ya es una URL absoluta, la usamos tal cual.
      urlFinal = rutaOUrl!;
    } else {
      // Si es una ruta relativa, le añadimos el prefijo del servidor.
      // `serverBaseUrl` será "http://..." en desarrollo y "" (vacío) en producción.
      // Esta operación es INSTANTÁNEA.
      urlFinal = ContenidoEduService.apiBaseUrl + rutaOUrl!;
    }

    debugPrint('[ImagenRedWidget] Mostrando imagen desde: $urlFinal');

    // --- PASO 3: Devolver el widget de imagen decorado ---
    // Usamos ClipRRect para aplicar el borde redondeado si existe.
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        urlFinal,
        height: height,
        width: width, // No uses double.infinity aquí, permite que se ajuste o sea nulo
        fit: fit,
        // --- Widget que se muestra mientras la imagen carga ---
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child; // La imagen ya cargó, muestra la imagen final.
          }
          // Si no queremos mostrar el loading, devolvemos un contenedor vacío.
          if (!mostrarLoadingWidget) {
            return SizedBox(height: height, width: width);
          }
          // Muestra un indicador de progreso.
          return Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0, // Un poco más delgado
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        // --- Widget que se muestra si ocurre un error al cargar ---
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '[ImagenRedWidget] Error cargando imagen: $urlFinal\n'
                'Error: $error',
          );
          return _buildPlaceholder('Error al cargar');
        },
        headers: const {
          'Accept': 'image/*', // Header estándar para solicitar imágenes
        },
      ),
    );
  }

  /// Widget de placeholder reutilizable para mostrar en caso de error o imagen nula.
  Widget _buildPlaceholder(String mensaje) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
