import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';


// Asegúrate de que las rutas de importación sean correctas para tu proyecto
import '../../models/contenido_educativo.dart';
import '../../widgets/imagen_red_widget.dart';
import '../../services/contenido_edu_service.dart';

class GestionarContenidoScreen extends StatefulWidget {
  const GestionarContenidoScreen({super.key});

  @override
  State<GestionarContenidoScreen> createState() =>
      _GestionarContenidoScreenState();
}

class _GestionarContenidoScreenState extends State<GestionarContenidoScreen> {
  final ContenidoEduService _servicio = ContenidoEduService();
  late Future<List<ContenidoEducativo>> _contenidosFuture;

  final ImagePicker _picker = ImagePicker();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _tipoMaterialController = TextEditingController();
  final _puntosClaveController = TextEditingController();
  final _etiquetasController = TextEditingController();
  final List<String> _categoria = [
    'tipos-materiales',
    'proceso-reciclaje',
    'consejos-practicos',
    'preparacion-materiales'
  ];
  final List<String> _materiales = [
    'todos',
    'aluminio',
    'cartón',
    'papel',
    'pet',
    'vidrio'
  ];
  String catSelect='tipos-materiales';
  String materialSelect='pet';
  @override
  void initState() {
    super.initState();
    _recargarContenidos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _contenidoController.dispose();
    _categoriaController.dispose();
    _tipoMaterialController.dispose();
    _puntosClaveController.dispose();
    _etiquetasController.dispose();
    super.dispose();
  }

  void _recargarContenidos() {
    setState(() {
      _contenidosFuture = _servicio.obtenerContenidoEducativo();
    });
  }

  Future<void> _eliminarContenido(String id, String titulo) async {
    final bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar el contenido de ${titulo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            child: Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon:  Icon(Icons.warning),
            label:  Text('Sí, eliminar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (confirmar) {
      try {
        final response = await _servicio.eliminarContenidoEducativo(id);
        if (response['statusCode'] == 200 || response['statusCode'] == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contenido eliminado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
          _recargarContenidos();
        } else {
          throw Exception(response['message'] ?? 'Error desconocido');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _mostrarDialogoEditar(ContenidoEducativo contenidoAEditar) {
    _tituloController.text = contenidoAEditar.titulo;
    _descripcionController.text = contenidoAEditar.descripcion;
    _contenidoController.text = contenidoAEditar.contenido;
    _categoriaController.text = contenidoAEditar.categoria;
    _tipoMaterialController.text = contenidoAEditar.tipoMaterial;
    _puntosClaveController.text = contenidoAEditar.puntosClave.join(', ');
    _etiquetasController.text = contenidoAEditar.etiquetas.join(', ');
    catSelect=contenidoAEditar.categoria;
    materialSelect=contenidoAEditar.tipoMaterial;


  List<XFile> _nuevasImagenes = [];
    // Rutas de imágenes actuales marcadas para eliminar
    Set<String> _imagenesAEliminar = {};
    // Índice (en la lista de imágenes actuales) de la imagen marcada como principal
    int? _imagenPrincipalExistente;
    // Inicializar índice principal si existe
    if (contenidoAEditar.imagenes.isNotEmpty) {
      final idx = contenidoAEditar.imagenes.indexWhere((img) => img.esPrincipal == true);
      _imagenPrincipalExistente = idx >= 0 ? idx : null;
    }

    bool _estaGuardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> _seleccionarImagenesDialog() async {
              // En web: usar file_picker para permitir multiple y obtener bytes
              if (kIsWeb) {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.image,
                  withData: true,
                );
                if (result != null && result.files.isNotEmpty) {
                  setStateDialog(() {
                    _nuevasImagenes = result.files.where((f) => f.bytes != null).map((f) => XFile.fromData(f.bytes!, name: f.name)).toList();
                  });
                }
                return;
              }

              // En móvil/desktop: usar image_picker
              final List<XFile>? imagenes = await _picker.pickMultiImage(imageQuality: 80);
              if (imagenes != null && imagenes.isNotEmpty) {
                setStateDialog(() {
                  _nuevasImagenes = imagenes;
                });
              }
            }
            Future<void> _guardarCambios() async {
              setStateDialog(() { _estaGuardando = true; });

              final puntosClaveList = _puntosClaveController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final etiquetasList = _etiquetasController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

              try {
                final response = await _servicio.actualizarContenidoEducativo(
                  id: contenidoAEditar.id,
                  titulo: _tituloController.text,
                  descripcion: _descripcionController.text,
                  contenido: _contenidoController.text,
                  categoria: catSelect,
                  tipoMaterial: materialSelect,
                  puntosClave: puntosClaveList,
                  etiquetas: etiquetasList,
                  nuevasImagenes: _nuevasImagenes,
                  idsImagenesAEliminar: _imagenesAEliminar.isNotEmpty ? _imagenesAEliminar.toList() : null,
                  imgPrincipal: _imagenPrincipalExistente,
                );

                if (response['statusCode'] == 200) {
                  Navigator.of(dialogContext).pop();
                  _recargarContenidos();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contenido actualizado con éxito'), backgroundColor: Colors.green),
                  );
                } else {
                  throw Exception(response['message'] ?? 'Respuesta inesperada del servidor');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
                );
              } finally {
                setStateDialog(() { _estaGuardando = false; });
              }
            }

            return AlertDialog(
              title: Text("Editar Contenido"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextFormField(_tituloController, 'Título','Agregue un título para el contenido'),
                      SizedBox(height: 15),
                      _buildTextFormField(_descripcionController, 'Descripción corta','Redacte una descripción acerca del contenido', maxLines: 3),
                      SizedBox(height: 15),
                      _buildTextFormField(_contenidoController, 'Contenido completo','Incluya la información referente al registro', maxLines: 6),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Categoría',
                                  hintText: 'Seleccione alguna de las categorías disponibles',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                value: catSelect,
                                items: _categoria.map((String valor) {
                                  return DropdownMenuItem<String>(
                                    value: valor,
                                    child: Text(
                                      valor.replaceAll('-', ' ').toUpperCase(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? nuevoValor) {
                                  // Usar setStateDialog en lugar de setState para evitar reconstruir el árbol padre
                                  setStateDialog(() {
                                    catSelect = nuevoValor!;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Tipo de material',
                                hintText: 'Seleccione alguno de los tipos de material disponibles',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              value: materialSelect,
                              items: _materiales.map((String valor) {
                                return DropdownMenuItem<String>(
                                  value: valor,
                                  child: Text(
                                    valor.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? nuevoValor) {
                                // Usar setStateDialog en lugar de setState para evitar reconstruir el árbol padre
                                setStateDialog(() {
                                  materialSelect = nuevoValor!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      _buildTextFormField(_puntosClaveController, 'Puntos clave (separados por coma)','Indique los puntos clave del registro'),
                      SizedBox(height: 15),
                      _buildTextFormField(_etiquetasController, 'Etiquetas (separadas por coma)','Indique las etiquetas referentes al registro'),
                      SizedBox(height: 20),


                      Text("Imágenes", style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 10),

                      if (_nuevasImagenes.isNotEmpty)
                        _buildVistaPreviaImagenesLocales(_nuevasImagenes)
                      else
                        Text("${contenidoAEditar.imagenes.length} imágenes actuales", style: TextStyle(color: Colors.grey, fontSize: 12)),

                      SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _seleccionarImagenesDialog,
                        icon: Icon(Icons.add_photo_alternate_outlined),
                        label: Text('Cambiar Imágenes'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _estaGuardando ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text("Cancelar"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _estaGuardando ? null : _guardarCambios,
                  icon: _estaGuardando
                      ? Container(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.save),
                  label: Text(_estaGuardando ? "Guardando..." : "Guardar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.green.shade200,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildTextFormField(TextEditingController controller, String label, String hinttext, {int maxLines = 1, String? validationMsg}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hinttext,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      validator: (value) {
        if (validationMsg != null && (value == null || value.isEmpty)) {
          return validationMsg;
        }
        return null;
      },
    );
  }

  Widget _buildVistaPreviaImagenesLocales(List<XFile> imagenes) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          final imagenFile = imagenes[index];
          return Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<List<int>>(
                future: imagenFile.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(width: 100, height: 100, color: Colors.grey[200]);
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(width: 100, height: 100, color: Colors.grey[300], child: Icon(Icons.broken_image));
                  }
                  return Image.memory(Uint8List.fromList(snapshot.data!), width: 100, height: 100, fit: BoxFit.cover);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagenWidget(dynamic imagenData, {double height = 160, BoxFit fit = BoxFit.cover}) {
    // Soporta: - String (ruta/URL remota) - XFile (archivo local seleccionado en web/móvil)
    if (imagenData is String && imagenData.isNotEmpty) {
      return ImagenRedWidget(
        rutaOUrl: imagenData,
        height: height,
        fit: fit,
      );
    } else if (imagenData is XFile) {
      return FutureBuilder<List<int>>(
        future: imagenData.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(height: height, color: Colors.grey[200]);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Container(height: height, color: Colors.grey[300], child: Icon(Icons.broken_image));
          }
          return Image.memory(Uint8List.fromList(snapshot.data!), height: height, width: double.infinity, fit: fit);
        },
      );
    }
    return Container(height: height, color: Colors.grey[200], child: Icon(Icons.photo, color: Colors.grey, size: 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FutureBuilder<List<ContenidoEducativo>>(
          future: _contenidosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No hay contenido para gestionar.'));
            }

            final contenidos = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _recargarContenidos(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: contenidos.map((contenido) => ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 800),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(contenido.titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImagenWidget(contenido.imagenPrincipal, height: 180, fit: BoxFit.contain),
                            ),
                            SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(color: Colors.green.shade200, borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(child: Text(contenido.descripcion, style: TextStyle(fontSize: 14))),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _mostrarDialogoEditar(contenido),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarContenido(contenido.id, contenido.titulo),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),


                  )).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
