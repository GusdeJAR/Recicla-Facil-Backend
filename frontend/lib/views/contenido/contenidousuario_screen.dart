import 'package:flutter/material.dart';
import '../../models/contenido_educativo.dart';
import '../../services/contenido_edu_service.dart';
import '../../widgets/imagen_red_widget.dart';
import 'contenidodetalle_screen.dart';

enum TipoBusqueda { porTermino, porCategoria, porTipoMaterial }

class ContenidoUsuarioScreen extends StatefulWidget {
  const ContenidoUsuarioScreen({super.key});

  @override
  State<ContenidoUsuarioScreen> createState() => _ContenidoUsuarioScreenState();
}

class _ContenidoUsuarioScreenState extends State<ContenidoUsuarioScreen> {
  final ContenidoEduService _contenidoService = ContenidoEduService();
  late Future<List<ContenidoEducativo>> _contenidosFuture;

  final TextEditingController _busquedaController = TextEditingController();
  final List<String> _opcionesTipoBusqueda = [
    'Término (título, desc., etiqueta)',
    'Categoría',
    'Tipo de Material', // Añadí esta para que coincida con tu lógica
    // Agrega más tipos si los necesitas
  ];
  String? _tipoBusquedaSeleccionada;
  List <String> opcionesCategoria = ['tipos-materiales', 'proceso-reciclaje', 'consejos-practicos', 'preparacion-materiales'];
  List <String> opcionesMaterial = ['todos', 'aluminio', 'cartón', 'papel', 'pet', 'vidrio'];
  String? categoriaSeleccionada;
  String? materialSeleccionado;

  @override
  void initState() {
    super.initState();
    _tipoBusquedaSeleccionada = _opcionesTipoBusqueda[0];
      _contenidosFuture = _cargarContenido();
  }

  Future<List<ContenidoEducativo>> _cargarContenido() async {
    // El switch ahora se convierte en el "director de orquesta" principal.
    switch (_tipoBusquedaSeleccionada) {
      case 'Término (título, desc., etiqueta)':
      // Si la búsqueda es por término, solo nos importa el TextField.
        final termino = _busquedaController.text.trim();
        if (termino.isEmpty) {
          // Si el campo de texto está vacío, obtenemos todo.
          print('Cargando todo el contenido...');
          return _contenidoService.obtenerContenidoEducativo();
        } else {
          // Si hay texto, buscamos por ese término.
          print('Buscando por término: $termino');
          return _contenidoService.buscarContenidoEducativo(termino);
        }

      case 'Categoría':
      // Si la búsqueda es por categoría, solo nos importa el Dropdown de categoría.
        final categoria = categoriaSeleccionada;
        if (categoria == null || categoria.isEmpty) {
          // Si no se ha seleccionado ninguna categoría, devolvemos todo
          // o una lista vacía para no mostrar nada hasta que se seleccione.
          // Devolver todo es más amigable.
          print('Cargando todo (ninguna categoría seleccionada)...');
          return _contenidoService.obtenerContenidoEducativo();
        } else {
          // Si hay una categoría seleccionada, la usamos para buscar.
          print('Buscando por categoría: $categoria');
          return _contenidoService.obtenerContenidoPorCategoria(categoria);
        }

      case 'Tipo de Material':
      // Si la búsqueda es por material, solo nos importa el Dropdown de material.
        final material = materialSeleccionado;
        if (material == null || material.isEmpty) {
          // Mismo caso que categoría.
          print('Cargando todo (ningún material seleccionado)...');
          return _contenidoService.obtenerContenidoEducativo();
        } else {
          // Si hay un material seleccionado, lo usamos para buscar.
          print('Buscando por tipo de material: $material');
          return _contenidoService.obtenerContenidoPorTipoMaterial(material);
        }

      default:
      // Caso por defecto: si algo sale mal, simplemente carga todo.
        print('Caso por defecto: cargando todo el contenido...');
        return _contenidoService.obtenerContenidoEducativo();
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildBarraDeBusqueda(),
              Expanded(
                child: FutureBuilder<List<ContenidoEducativo>>(
                  future: _contenidosFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      debugPrint("FUTUREBUILDER ERROR: ${snapshot.error}");
                      debugPrint("STACKTRACE: ${snapshot.stackTrace}");
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Error: ${snapshot.error}',
                              textAlign: TextAlign.center),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      debugPrint("FUTUREBUILDER ERROR: snapshot.data es null.");
                      return Center(
                        child: Text('No se encontraron resultados.',
                            style: TextStyle(fontSize: 16)),
                      );
                    }

                    final contenidos = snapshot.data!;
                    if (contenidos.isEmpty) {
                      return const Center(
                        child: Text('No se encontraron resultados.'),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.all(0),
                      itemCount: contenidos.length,
                      itemBuilder: (context, index) {
                        final contenido = contenidos[index];
                        return InkWell(
                          onTap: () {
                            debugPrint("Navegando a detalles para el contenido con ID: ${contenido.id}");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContenidoDetalleScreen(contenidoId: contenido.id),
                              ),
                            );
                          },
                          child: _buildContenidoCard(contenido),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función auxiliar solo para el TextField y su botón
  Widget _buildTextFieldBusqueda() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              labelText: 'Escriba un valor.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _busquedaController.clear();
                  setState(() {
                    _contenidosFuture = _cargarContenido();
                  });
                },
              ),
            ),
            onSubmitted: (_) {
              setState(() {
                _contenidosFuture = _cargarContenido();
              });
            },
          ),
        ),
        SizedBox(width: 12),
        ElevatedButton.icon(
          icon: Icon(Icons.search),
          label: Text('Buscar'),
          onPressed: () {
            setState(() {
              _contenidosFuture = _cargarContenido();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ],
    );
  }


  // Esta función construye la UI de búsqueda dinámicamente
  Widget _buildSearchUI() {
    switch (_tipoBusquedaSeleccionada) {
      case 'Término (título, desc., etiqueta)':
      // Muestra el TextField para búsqueda por término
        return _buildTextFieldBusqueda(); // Usamos una función auxiliar

      case 'Categoría':
      // Muestra el Dropdown de Categorías
        return DropdownButtonFormField<String>(
          value: categoriaSeleccionada,
          hint: Text('Seleccione una categoría'),
          decoration: InputDecoration(
            labelText: 'Categoría',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          items: opcionesCategoria.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              categoriaSeleccionada = newValue;
              // Opcional: puedes disparar la búsqueda aquí mismo
              _contenidosFuture = _cargarContenido();
            });
          },
        );

      case 'Tipo de Material':
      // Muestra el Dropdown de Tipos de Material
        return DropdownButtonFormField<String>(
          value: materialSeleccionado,
          hint: Text('Seleccione un material'),
          decoration: InputDecoration(
            labelText: 'Tipo de Material',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          items: opcionesMaterial.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              materialSeleccionado = newValue;
              // Opcional: puedes disparar la búsqueda aquí mismo
              _contenidosFuture = _cargarContenido();
            });
          },
        );

      default:
      // Muestra un widget vacío o un placeholder si no hay nada seleccionado
        return SizedBox.shrink();
    }
  }


  Widget _buildBarraDeBusqueda() {
    return Container(
          padding: EdgeInsets.all(16.0),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _tipoBusquedaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Buscar por',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                items: _opcionesTipoBusqueda.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoBusquedaSeleccionada = newValue;
                    categoriaSeleccionada = null;
                    materialSeleccionado = null;
                    _busquedaController.clear();
                    _contenidosFuture = _cargarContenido();
                  });
                },
              ),

              SizedBox(height: 12),
              _buildSearchUI(),
            ],
          ),
        );
  }

  Widget _buildContenidoCard(ContenidoEducativo contenido) {
    final String? urlOPath = contenido.imagenPrincipal;
    debugPrint("URL/ruta para la tarjeta '${contenido.titulo}': $urlOPath");

    return Card(
      elevation: 4.0,
      margin: EdgeInsets.only(bottom: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagenRedWidget(
            rutaOUrl: urlOPath,
            height: 220,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contenido.titulo,
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.0),
                Text(
                  contenido.descripcion,
                  style: TextStyle(fontSize: 15.0, color: Colors.grey[700], height: 1.4), // Mejor interlineado
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                Chip(
                  label: Text(contenido.categoria),
                  avatar: Icon(Icons.category_outlined, size: 18),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade800),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                Chip(
                  label: Text(contenido.tipoMaterial),
                  avatar: Icon(Icons.inventory_2_outlined, size: 18),
                  backgroundColor: Colors.teal.shade50,
                  labelStyle: TextStyle(color: Colors.teal.shade800),
                  side: BorderSide(color: Colors.teal.shade100),
                ),
              ],
            ),
          ),

          if (contenido.puntosClave.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(thickness: 1),
                  SizedBox(height: 8.0),
                  Text(
                    "Puntos clave",
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 8.0),
                  Column(
                    children: contenido.puntosClave.map((punto) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                punto,
                                style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

}
