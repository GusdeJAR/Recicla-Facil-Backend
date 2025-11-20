import 'package:flutter/material.dart';
import '../models/contenido_educativo.dart';
import '../services/contenido_edu_service.dart';

// Creamos un widget con estado para que maneje su propia lógica de forma aislada.
class DetalleContenidoDialog extends StatefulWidget {
  final ContenidoEducativo contenido;

  const DetalleContenidoDialog({super.key, required this.contenido});

  @override
  State<DetalleContenidoDialog> createState() => _DetalleContenidoDialogState();
}

class _DetalleContenidoDialogState extends State<DetalleContenidoDialog> {
  String? imagenFinalUrl;

  @override
  void initState() {
    super.initState();
    // La lógica para construir la URL se hace una sola vez, al iniciar el widget.
    _construirUrlDeImagen();
  }

  void _construirUrlDeImagen() {
    final String? urlOPath = widget.contenido.imagenPrincipal;
    if (urlOPath != null && urlOPath.isNotEmpty) {
      if (urlOPath.startsWith('http')) {
        imagenFinalUrl = urlOPath;
      } else {
        imagenFinalUrl = ContenidoEduService.serverBaseUrl + urlOPath;
      }
    }
    // No usamos setState aquí porque initState se ejecuta antes del primer build.
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Construyendo diálogo con URL: $imagenFinalUrl");

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // El widget de imagen, ahora 100% aislado y seguro.
            if (imagenFinalUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                child: Image.network(
                  imagenFinalUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("Error al cargar imagen en diálogo: $error");
                    return Container(
                      height: 220,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                    );
                  },
                ),
              ),

            // Contenido del diálogo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contenido.titulo,
                    style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    widget.contenido.contenido,
                    style: TextStyle(fontSize: 15.0, color: Colors.grey[800], height: 1.4),
                  ),
                  // ... (Aquí iría tu lógica de Puntos Clave, etc.)
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
