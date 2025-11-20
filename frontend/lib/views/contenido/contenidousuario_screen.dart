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
  TipoBusqueda _tipoBusquedaSeleccionada = TipoBusqueda.porTermino; // Valor por defecto

  @override
  void initState() {
    super.initState();
    _contenidosFuture = _cargarContenido();
  }

  Future <List<ContenidoEducativo>> _cargarContenido() async{
    if (_busquedaController.text.isEmpty) {
      return _contenidoService.obtenerContenidoEducativo();
    } else {
      final termino = _busquedaController.text;
      switch (_tipoBusquedaSeleccionada) {
        case TipoBusqueda.porTermino:
          return _contenidoService.buscarContenidoEducativo(termino);
        case TipoBusqueda.porCategoria:
          return _contenidoService.obtenerContenidoPorCategoria(termino);
        case TipoBusqueda.porTipoMaterial:
          return _contenidoService.obtenerContenidoPorTipoMaterial(termino);
      }
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

  Widget _buildBarraDeBusqueda() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800),
        child: Container(
          padding: EdgeInsets.all(16.0),
          color: Colors.white,
          child: Column(
            children: [
              DropdownButtonFormField<TipoBusqueda>(
                value: _tipoBusquedaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Buscar por:',
                  hintText: 'Seleccione alguna de las opciones para hacer la búsqueda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                ),
                items: [
                  DropdownMenuItem(
                    value: TipoBusqueda.porTermino,
                    child: Text('Término (título, desc., etiqueta)'),
                  ),
                  DropdownMenuItem(
                    value: TipoBusqueda.porCategoria,
                    child: Text('Categoría'),
                  ),
                  DropdownMenuItem(
                    value: TipoBusqueda.porTipoMaterial,
                    child: Text('Tipo de material'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tipoBusquedaSeleccionada = value;
                    });
                  }
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _busquedaController,
                      decoration: InputDecoration(
                        labelText: 'Escriba un valor.',
                        hintText: 'Ingrese un dato para realizar la búsqueda con base a ello',
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
                    onPressed: (){
                      setState(() {
                        _contenidosFuture = _cargarContenido();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    ),
                  ),
                ]
              ),
            ],
          ),
        ),
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
