import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/punto_reciclaje.dart';
import '../../providers/auth_provider.dart';
import '../../providers/puntos_provider.dart';
import '../../services/puntos_reciclaje_service.dart';
import 'solicitudes_puntos_screen.dart';

class PuntosScreen extends StatefulWidget {
  const PuntosScreen({super.key});

  @override
  State<PuntosScreen> createState() => _PuntosScreenState();
}

class _PuntosScreenState extends State<PuntosScreen> {
  bool isAdmin = false;
  String? _materialFiltro;
  bool _mostrarMapa = false;
  LatLng? _currentLocation;
  MapController _mapController = MapController();

  final List<String> _tiposMaterial = [
    'Todos',
    'Aluminio',
    'Cartón',
    'Papel',
    'PET',
    'Vidrio',
  ];

  static const LatLng _centroTepic = LatLng(21.5018, -104.8946);

  @override
  void initState() {
    super.initState();
    _materialFiltro = 'Todos';
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PuntosProvider>(context, listen: false).cargarPuntos();
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always)
        return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error obteniendo ubicación: $e');
    }
  }

  void _navegarANuevaSolicitud() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NuevaSolicitudPuntoScreen()),
    );

    if (resultado == true) {
      // Pequeño delay para asegurar que la base de datos haya guardado
      await Future.delayed(Duration(milliseconds: 500));
      Provider.of<PuntosProvider>(
        context,
        listen: false,
      ).cargarPuntos(material: _materialFiltro!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdmin
                ? '¡Punto de reciclaje creado y publicado exitosamente!'
                : '¡Solicitud enviada exitosamente!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navegarAMisSolicitudes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SolicitudesPuntosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puntosProvider = context.watch<PuntosProvider>();
    final bool _isLoading = puntosProvider.isLoading;
    final List<PuntoReciclaje> _puntosEncontrados = puntosProvider.puntos;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Puntos de Reciclaje',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Botón para administradores - Crear punto directamente
          if (isAdmin)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.add_location,
                  color: Colors.blue[700],
                  size: 24,
                ),
                onPressed: _navegarANuevaSolicitud,
                tooltip: 'Crear punto directamente',
              ),
            ),

          // Botón para usuarios normales - Mis solicitudes
          if (!isAdmin)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.list_alt, color: Colors.green[700], size: 24),
                onPressed: _navegarAMisSolicitudes,
                tooltip: 'Mis solicitudes',
              ),
            ),

          // Botón para cambiar entre mapa y lista
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                _mostrarMapa ? Icons.list : Icons.location_on,
                color: Colors.green[700],
                size: 24,
              ),
              onPressed: () => setState(() => _mostrarMapa = !_mostrarMapa),
              tooltip: _mostrarMapa ? 'Ver lista' : 'Ver mapa',
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Sección de búsqueda
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Buscador de puntos de reciclaje",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // Información para usuario normal
                if (!isAdmin)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '¿No encuentras un punto? ¡Solicita agregarlo!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _navegarANuevaSolicitud,
                          child: Text(
                            'Solicitar',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _materialFiltro,
                        decoration: InputDecoration(
                          labelText: 'Filtro de material',
                          hintText:
                              'Seleccione uno de los materiales para buscar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.filter_list),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                        items: _tiposMaterial.map((material) {
                          return DropdownMenuItem<String>(
                            value: material,
                            child: Text(material),
                          );
                        }).toList(),
                        onChanged: (String? nuevoValor) {
                          setState(() => _materialFiltro = nuevoValor);
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _buscarPuntos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Buscar'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '${_puntosEncontrados.length} centros encontrados',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _puntosEncontrados.isEmpty
                ? _buildEmptyState()
                : _mostrarMapa
                ? _construirMapa(_puntosEncontrados)
                : _construirLista(_puntosEncontrados),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No se encontraron puntos de reciclaje',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                isAdmin
                    ? 'Usa el botón de la barra superior para crear un nuevo punto'
                    : 'Puedes solicitar agregar un nuevo punto de reciclaje en tu zona',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              // Solo mostrar botón para usuarios normales
              if (!isAdmin)
                ElevatedButton.icon(
                  onPressed: _navegarANuevaSolicitud,
                  icon: Icon(Icons.add_location_alt),
                  label: Text('Solicitar nuevo punto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),

              SizedBox(height: 16),

              // Botón para ver solicitudes
              TextButton(
                onPressed: _navegarAMisSolicitudes,
                child: Text(
                  isAdmin
                      ? 'Gestionar solicitudes'
                      : 'Ver mis solicitudes anteriores',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirLista(List<PuntoReciclaje> puntos) {
    return ListView.builder(
      itemCount: puntos.length,
      itemBuilder: (context, index) {
        final centro = puntos[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(Icons.recycling, color: Colors.green),
            title: Text(
              centro.nombre,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(centro.direccion),
            trailing: Icon(Icons.chevron_right, color: Colors.green),
            onTap: () => _mostrarDetallesCentro(centro),
          ),
        );
      },
    );
  }

  Widget _construirMapa(List<PuntoReciclaje> puntos) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentLocation ?? _centroTepic,
            zoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.rf_sprint1.app',
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    builder: (ctx) => Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: puntos.map((centro) {
                return Marker(
                  point: centro.coordenadas,
                  builder: (ctx) => GestureDetector(
                    onTap: () => _mostrarDetallesCentro(centro),
                    child: Tooltip(
                      message: centro.nombre,
                      child: Icon(
                        Icons.recycling,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // Solo el botón para centrar en la ubicación del usuario
        if (_currentLocation != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _mapController.move(_currentLocation!, 15.0),
              child: Icon(Icons.my_location),
              backgroundColor: Colors.green,
              mini: true,
            ),
          ),
      ],
    );
  }

  void _mostrarDetallesCentro(PuntoReciclaje centro) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.recycling, color: Colors.green, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        centro.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  centro.descripcion,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                _buildInfoRow(Icons.location_on, centro.direccion),
                _buildInfoRow(Icons.phone, centro.telefono),
                _buildInfoRow(Icons.access_time, centro.horario),
                SizedBox(height: 16),
                Text(
                  'Materiales aceptados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: centro.tipoMaterial.map((material) {
                    return Chip(
                      label: Text(
                        material,
                        style: TextStyle(color: Colors.green[800]),
                      ),
                      backgroundColor: Colors.green[100],
                      side: BorderSide(color: Colors.green.shade200),
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                // Botón para sugerir mejoras (solo para usuarios normales)
                if (!isAdmin)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _navegarANuevaSolicitud,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green),
                      ),
                      child: Text('Sugerir punto similar'),
                    ),
                  ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'Cerrar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _buscarPuntos() async {
    Provider.of<PuntosProvider>(
      context,
      listen: false,
    ).cargarPuntos(material: _materialFiltro!);
  }
}
