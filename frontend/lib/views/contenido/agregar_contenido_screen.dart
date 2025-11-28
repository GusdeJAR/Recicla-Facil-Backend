import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../models/cloudinary_image.dart';
import '../../services/contenido_edu_service.dart';

class AgregarContenidoScreen extends StatefulWidget {
  const AgregarContenidoScreen({super.key});

  @override
  State<AgregarContenidoScreen> createState() => _AgregarContenidoScreenState();
}

class _AgregarContenidoScreenState extends State<AgregarContenidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contenidoService = ContenidoEduService();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _tipoMaterialController = TextEditingController();
  final _puntosClaveController = TextEditingController();
  final _etiquetasController = TextEditingController();
  final List<XFile> _imagenesSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();
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
    'vidrio',

  ];
  String catSelect='tipos-materiales';
  String materialSelect='pet';


  bool _estaCargando = false;
  int? _imagenPrincipalIndex;

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

  // --- LÓGICA DE LA PANTALLA ---

  /// Simula la subida de una imagen a un servicio de almacenamiento
  /// y devuelve una URL de ejemplo.
  /// En una app real, aquí llamarías a Firebase Storage, Cloudinary, etc.


  Future<void> _agregarContenido() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor, completa todos los campos obligatorios.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (_imagenesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Debes seleccionar al menos una imagen.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_imagenPrincipalIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor, selecciona una imagen como principal.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _estaCargando = true);
    try {
      // 1. 🚀 SUBIDA DE IMÁGENES A CLOUDINARY
      // Mapeamos el array de XFile a un array de Promesas de subida
      final uploadPromises = _imagenesSeleccionadas.map((imagen) => ContenidoEduService.subirImagen(imagen)).toList();

      // Esperamos a que todas las subidas terminen
      final List<CloudinaryImage> imagenesCloudinary = await Future.wait(uploadPromises);

      // 2. PREPARACIÓN DE DATOS PARA EL BACKEND (Serialización JSON)
      final imagenesPreSubidasList = imagenesCloudinary.map((img) => img.toJson()).toList();

      // Convertimos la lista de mapas a un String JSON
      final String imagenesPreSubidasJson = json.encode(imagenesPreSubidasList);

      // 3. PREPARACIÓN DE CAMPOS DE TEXTO/ARRAYS
      final puntosClave = _puntosClaveController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final etiquetas = _etiquetasController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // 4. LLAMADA AL SERVICIO (usando el nuevo campo imagenesPreSubidas)
      final response = await _contenidoService.crearContenidoEducativo(
        titulo: _tituloController.text,
        descripcion: _descripcionController.text,
        contenido: _contenidoController.text,
        categoria: catSelect,
        tipoMaterial: materialSelect,

        // 🆕 Enviar el nuevo campo JSON que el backend espera
        imagenesPreSubidas: imagenesPreSubidasJson,

        puntosClave: puntosClave,
        accionesCorrectas: [],
        accionesIncorrectas: [],
        etiquetas: etiquetas,
        publicado: true,

        // El backend necesita el índice de la imagen principal como string
        imgPrincipal: _imagenPrincipalIndex!,
      );

      if (mounted && response['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('¡Contenido "${response['contenido']['titulo']}" creado con éxito!'),
              backgroundColor: Colors.green),
        );
        _limpiarFormulario();
      } else {
        throw Exception(response['mensaje'] ?? 'Error desconocido al crear contenido.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _estaCargando = false);
      }
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _tituloController.clear();
    _descripcionController.clear();
    _contenidoController.clear();
    _categoriaController.clear();
    _tipoMaterialController.clear();
    _puntosClaveController.clear();
    _etiquetasController.clear();
    setState(() {
      _imagenesSeleccionadas.clear();
      _imagenPrincipalIndex = null;
    });
  }

  // Recomendado: usar file_picker en web para selección múltiple, image_picker en móvil
  Future<List<XFile>> _seleccionarMultiplesImagenes() async {
    // Web: usar file_picker para asegurar que el input permita multiple
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result == null) return <XFile>[];
      final archivos = result.files.where((f) => f.bytes != null).map((f) => XFile.fromData(f.bytes!, name: f.name)).toList();
      return archivos;
    }

    // Móvil / escritorio: usar image_picker
    final List<XFile>? seleccion = await _picker.pickMultiImage(imageQuality: 80);
    return seleccion ?? <XFile>[];
  }

  Future<void> _seleccionarImagenes() async {
    final imagenes = await _seleccionarMultiplesImagenes();
    if (imagenes.isNotEmpty) {
      setState(() {
        _imagenesSeleccionadas.addAll(imagenes);
        if (_imagenPrincipalIndex == null && _imagenesSeleccionadas.isNotEmpty) {
          _imagenPrincipalIndex = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Agregar Contenido Nuevo'),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextFormField(
                    _tituloController,
                    'Título',
                    'Agregue un título para el contenido',
                    validationMsg: 'El título es obligatorio',
                  ),
                  SizedBox(height: 15),
                  _buildTextFormField(
                    _descripcionController,
                    'Descripción corta',
                    'Redacte una descripción acerca del contenido',
                    validationMsg: 'La descripción es obligatoria',
                    maxLines: 3,
                  ),
                  SizedBox(height: 15),
                  _buildTextFormField(
                    _contenidoController,
                    'Contenido completo',
                    'Incluya la información referente al registro',
                    validationMsg: 'El contenido es obligatorio',
                    maxLines: 6,
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
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
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? nuevoValor) {
                            setState(() {
                              catSelect = nuevoValor!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Flexible(
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
                            setState(() {
                              materialSelect = nuevoValor!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  _buildTextFormField(_puntosClaveController, 'Puntos clave (separados por coma)', 'Indique los puntos clave del registro, siendo subtemas o características.'),
                  SizedBox(height: 15),
                  _buildTextFormField(_etiquetasController, 'Etiquetas (separadas por coma)','Indique las etiquetas referentes al registro, siendo conceptos para su búsqueda.'),
                  SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _seleccionarImagenes,
                    icon: Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Seleccionar imágenes'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (_imagenesSeleccionadas.isNotEmpty)
                    _buildVistaPreviaImagenes(),

                  SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _estaCargando ? null : _agregarContenido,
                      icon: _estaCargando
                          ? Container(
                        width: 24,
                        height: 24,
                        padding: EdgeInsets.all(2.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                          : Icon(Icons.add_task),
                      label: Text(_estaCargando ? 'Guardando...' : 'Guardar contenido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller,
      String label, String hinttext, {
        String? validationMsg,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines, // Ahora se usa el parámetro nombrado
      decoration: InputDecoration(
        labelText: label,
        hintText: hinttext,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (validationMsg != null && (value == null || value.isEmpty)) {
          return validationMsg;
        }
        return null;
      },
    );
  }

  Widget _buildVistaPreviaImagenes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imágenes seleccionadas (toca una para hacerla principal):', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagenesSeleccionadas.length,
            itemBuilder: (context, index) {
              final isPrincipal = index == _imagenPrincipalIndex;
              final imagenFile = _imagenesSeleccionadas[index];
              return GestureDetector(
                onTap: () => setState(() => _imagenPrincipalIndex = index),
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isPrincipal ? Border.all(color: Colors.green, width: 3) : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isPrincipal ? 5 : 8),
                          // Usar Image.memory para mostrar preview en todas las plataformas
                          child: FutureBuilder<List<int>>(
                            future: imagenFile.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Container(width: 120, height: 120, color: Colors.grey[200]);
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Container(width: 120, height: 120, color: Colors.grey[300], child: Icon(Icons.broken_image));
                              }
                              return Image.memory(
                                Uint8List.fromList(snapshot.data!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      if (isPrincipal)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
                            ),
                            child: Text('Principal', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      Positioned(
                        top: -10,
                        right: -10,
                        child: IconButton(
                          icon: Icon(Icons.cancel, color: Colors.redAccent),
                          onPressed: () => setState(() {
                            _imagenesSeleccionadas.removeAt(index);
                            if (_imagenPrincipalIndex == index) {
                              _imagenPrincipalIndex = _imagenesSeleccionadas.isNotEmpty ? 0 : null;
                            } else if (_imagenPrincipalIndex != null && _imagenPrincipalIndex! > index) {
                              _imagenPrincipalIndex = _imagenPrincipalIndex! - 1;
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
