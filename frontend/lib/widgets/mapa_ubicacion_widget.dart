// lib/widgets/mapa_ubicacion_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';
import 'dart:async';

class MapaUbicacionWidget extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String? nombreUbicacion;
  final VoidCallback? onCerrar;
  final Function(double lat, double lon, DireccionDesdeCoordenas? direccion)? onUbicacionActualizada;

  const MapaUbicacionWidget({
    super.key,
    required this.latitud,
    required this.longitud,
    this.nombreUbicacion,
    this.onCerrar,
    this.onUbicacionActualizada,
  });

  @override
  State<MapaUbicacionWidget> createState() => _MapaUbicacionWidgetState();
}

class _MapaUbicacionWidgetState extends State<MapaUbicacionWidget> {
  late LatLng _posicionActual;
  bool _cargando = false;
  String? _direccionObtenida;
  String? _errorMensaje;
  final GeocodingService _geocodingService = GeocodingService();
  Timer? _debounceTimer;
  String? _lastHash;
  bool _bloquearPosicion = false;

  @override
  void initState() {
    super.initState();
    _posicionActual = LatLng(widget.latitud, widget.longitud);
  }

  DireccionDesdeCoordenas? _ultimaDireccion;

  Future<void> _obtenerDireccion(LatLng nuevaPosicion) async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final direccion = await _geocodingService.obtenerDireccionDesdeCoordenas(
        latitud: nuevaPosicion.latitude,
        longitud: nuevaPosicion.longitude,
      );

      setState(() {
        final tieneCalle = direccion.calle != null && direccion.calle!.isNotEmpty && !direccion.calle!.toLowerCase().contains('desconocida');
        final tieneColonia = direccion.colonia != null && direccion.colonia!.isNotEmpty && !direccion.colonia!.toLowerCase().contains('desconocida');

        if (tieneCalle || tieneColonia) {
          _direccionObtenida = 'Calle: ${direccion.calle ?? "N/A"}\nNúmero: ${direccion.numero ?? "S/N"}\nColonia: ${direccion.colonia ?? "N/A"}';
          _ultimaDireccion = direccion;
          _errorMensaje = null;
        } else {
          _direccionObtenida = 'Dirección no disponible en esta ubicación.\nUsa el campo de dirección manual.';
          _ultimaDireccion = null;
          _errorMensaje = 'Los datos de dirección no son confiables para esta ubicación';
        }
        _cargando = false;
      });

      // Notificar al widget padre
      widget.onUbicacionActualizada?.call(
        nuevaPosicion.latitude,
        nuevaPosicion.longitude,
        _ultimaDireccion,
      );
    } catch (e) {
      print('Error en _obtenerDireccion: $e');
      setState(() {
        _errorMensaje = 'Error al obtener dirección: $e';
        _cargando = false;
      });
    }
  }

  String _hashPos(LatLng p) => '${(p.latitude * 100000).round()}|${(p.longitude * 100000).round()}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            color: Colors.green,
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ajustar - ${widget.nombreUbicacion ?? "Ubicación"}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onCerrar ?? () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Mapa interactivo
          Container(
            height: 400,
            width: double.maxFinite,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    center: _posicionActual,
                    zoom: 17.0,
                    onTap: (tapPosition, point) {
                      // Permitir click en el mapa para colocar marcador
                      if (_bloquearPosicion) return; // Si está bloqueado, ignorar taps

                      setState(() => _posicionActual = point);

                      final hash = _hashPos(point);
                      if (hash == _lastHash) return; // Ignorar cambios mínimos
                      _lastHash = hash;

                      // Debounce para limitar llamadas a la API
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 700), () {
                        _obtenerDireccion(point);
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.reciclaFacil',
                      additionalOptions: {
                        'access_token': '',
                      },
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _posicionActual,
                          width: 50,
                          height: 50,
                          builder: (ctx) => GestureDetector(
                            onPanUpdate: (details) {
                              // Permite arrastrar el marcador
                              // Nota: Para arrastrar correctamente necesitarías
                              // transformar las coordenadas de pantalla a LatLng
                              // Por ahora, usamos tap del mapa
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Overlay con instrucciones
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Toca el mapa para ajustar la ubicación',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Indicador de carga
                if (_cargando)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black12,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Footer con información
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordenadas Actuales:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Lat: ${_posicionActual.latitude.toStringAsFixed(6)}'),
                Text('Lon: ${_posicionActual.longitude.toStringAsFixed(6)}'),
                SizedBox(height: 16),
                if (_direccionObtenida != null) ...[
                  Text(
                    'Dirección Detectada:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _direccionObtenida!,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  SizedBox(height: 16),
                ],
                if (_errorMensaje != null)
                  Text(
                    _errorMensaje!,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 12),
                Text(
                  'Nota: Toca el mapa para ajustar la ubicación. La dirección se actualizará automáticamente.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // Botones
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      widget.onCerrar ?? () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                  label: Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Guardar la ubicación ajustada y enviar también la dirección
                    widget.onUbicacionActualizada?.call(
                      _posicionActual.latitude,
                      _posicionActual.longitude,
                      _ultimaDireccion,
                    );
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.check),
                  label: Text('Guardar Ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
