import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rf_sprint1/services/solicitudes_puntos_service.dart';
import 'package:rf_sprint1/services/geocoding_service.dart';
import 'package:rf_sprint1/models/solicitud_punto.dart';
import 'package:rf_sprint1/widgets/mapa_ubicacion_widget.dart';
import '../../providers/admin_solicitudes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/solicitudes_provider.dart';

class SolicitudesPuntosScreen extends StatefulWidget {
  const SolicitudesPuntosScreen({super.key});

  @override
  State<SolicitudesPuntosScreen> createState() => _SolicitudesPuntosScreenState();
}

class _SolicitudesPuntosScreenState extends State<SolicitudesPuntosScreen> {
  bool _mostrarSoloPendientes = true;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        Provider.of<SolicitudesProvider>(context, listen: false)
            .cargarSolicitudesUsuario(authProvider.userName!, authProvider.isAdmin);
      }
    });
  }

  Future<void> _cargarSolicitudes() async {

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        // Usar el nombre de usuario real del AuthProvider
        await Provider.of<SolicitudesProvider>(context, listen: false)
            .cargarSolicitudesUsuario(authProvider.userName!, authProvider.isAdmin);
      } else {
        _mostrarError('Debes iniciar sesión para ver tus solicitudes');
      }

  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<SolicitudPunto> _getSolicitudesFiltradas(List<SolicitudPunto> solicitudes) {
    if (_mostrarSoloPendientes) {
      return solicitudes.where((s) => s.estado == 'pendiente').toList();
    }
    return solicitudes;
  }

  void _nuevaSolicitud() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NuevaSolicitudPuntoScreen()),
    );
    if (resultado == true) {
      _mostrarExito('Solicitud creada exitosamente');
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitudesProvider = context.watch<SolicitudesProvider>();
    final solicitudesFiltradas = _getSolicitudesFiltradas(solicitudesProvider.solicitudes);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis solicitudes de puntos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<bool>(
            onSelected: (value) {
              setState(() {
                _mostrarSoloPendientes = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(_mostrarSoloPendientes ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Solo pendientes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(!_mostrarSoloPendientes ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Todas las solicitudes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: solicitudesProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : solicitudesFiltradas.isEmpty
              ? _buildEmptyState()
              : _buildListaSolicitudes(solicitudesFiltradas),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_mis_solicitudes',
        onPressed: _nuevaSolicitud,
        child: Icon(Icons.add_location_alt),
        backgroundColor: Colors.green,
        tooltip: 'Solicitar nuevo punto',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _mostrarSoloPendientes 
                ? 'No tienes solicitudes pendientes'
                : 'No has realizado ninguna solicitud',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Presiona el botón + para crear una nueva solicitud',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaSolicitudes(List<SolicitudPunto> solicitudes) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${solicitudes.length} solicitud(es) ${_mostrarSoloPendientes ? 'pendientes' : 'en total'}',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              return _buildTarjetaSolicitud(solicitudes[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaSolicitud(SolicitudPunto solicitud) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    solicitud.nombre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    _obtenerTextoEstado(solicitud.estado),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _obtenerColorEstado(solicitud.estado),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Descripción
            Text(
              solicitud.descripcion,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            
            // Dirección
            _buildInfoItem(
              Icons.location_on,
              '${solicitud.direccion.calle} ${solicitud.direccion.numero}, ${solicitud.direccion.colonia}',
            ),
            SizedBox(height: 8),
            
            // Teléfono
            _buildInfoItem(
              Icons.phone,
              solicitud.telefono,
            ),
            SizedBox(height: 8),
            
            // Horario
            _buildInfoItem(
              Icons.access_time,
              solicitud.horario,
            ),
            SizedBox(height: 12),
            
            // Materiales
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: solicitud.tipoMaterial.map((material) {
                return Chip(
                  label: Text(material),
                  backgroundColor: Colors.green[50],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            
            // Comentarios del admin si existe
            if (solicitud.comentariosAdmin != null && solicitud.comentariosAdmin!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comentarios del administrador:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(solicitud.comentariosAdmin!),
                      ],
                    ),
                  ),
                ],
              ),
            SizedBox(height: 12),
            Text(
              'Solicitado: ${_formatearFecha(solicitud.fechaCreacion)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _obtenerTextoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'aprobada':
        return 'APROBADA';
      case 'rechazada':
        return 'RECHAZADA';
      default:
        return estado.toUpperCase();
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

// Pantalla para nueva solicitud de punto de reciclaje
class NuevaSolicitudPuntoScreen extends StatefulWidget {
  @override
  _NuevaSolicitudPuntoScreenState createState() => _NuevaSolicitudPuntoScreenState();
}

class _NuevaSolicitudPuntoScreenState extends State<NuevaSolicitudPuntoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _telefonoController = TextEditingController();
  List <String> opcionesDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  List <String> opcionesHora = ['8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00', '11:30', '12:00',
    '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00',
        '18:30', '19:00'];
  String? diaSeleccionado1;
  String? diaSeleccionado2;
  String? horaSeleccionada1;
  String? horaSeleccionada2;
  String horario="";
  final SolicitudesPuntosService _solicitudesService = SolicitudesPuntosService();
  final GeocodingService _geocodingService = GeocodingService();
  
  // Usar la lista del servicio para mantener consistencia
  List<String> get _tiposMaterial => _solicitudesService.tiposMaterialDisponibles
      .where((material) => material != 'Todos') // Excluir "Todos" ya que es para filtros
      .toList();
      
  List<String> _tiposSeleccionados = [];
  bool _enviando = false;
  
  // Variables para validación y preview
  UbicacionPreview? _ubicacionPreview;
  bool _geocodificandoPreview = false;
  bool _direccionValida = false;

  List<String> getOpcionesDias2() {
    if (diaSeleccionado1 == null) {
      return [];
    }
    final int startIndex = opcionesDias.indexOf(diaSeleccionado1!);
    return opcionesDias.sublist(startIndex + 1);
  }

  List<String> getOpcionesHoras2() {
    if (horaSeleccionada1 == null) {
      return [];
    }
    final int startIndex = opcionesHora.indexOf(horaSeleccionada1!);
    return opcionesHora.sublist(startIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> opcionesDias2 = getOpcionesDias2();
    final List<String> opcionesHoras2 = getOpcionesHoras2();
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitar nuevo punto de reciclaje'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInfoSection(),
              SizedBox(height: 20),
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre del punto de reciclaje *',
                hintText: 'Ej: Centro de Acopio Ecológico Tepic',
                validator: (value) => value!.isEmpty ? 'Ingresa el nombre del punto' : null,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _descripcionController,
                label: 'Descripción del punto *',
                hintText: 'Ej: Centro especializado en reciclaje de plástico y vidrio',
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Ingresa una descripción' : null,
              ),
              SizedBox(height: 16),
              _buildDireccionSection(),
              SizedBox(height: 16),
              _buildMaterialSelector(),
              SizedBox(height: 16),
              _buildTextField(
                controller: _telefonoController,
                label: 'Teléfono de contacto *',
                hintText: 'Ej: 3111234567',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.isEmpty) return 'Ingresa un teléfono de contacto';
                  if (value.length < 10) {
                    return 'El número de teléfono no puede ser menor a diez cifras';
                  }
                  if (value.length > 10) {
                    return 'El número de teléfono no puede ser mayor a diez cifras';
                  }
                }
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: diaSeleccionado1,
                      hint: Text("Día de inicio del horario:"),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                        hintText: 'Seleccione un día de inicio del horario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      items: opcionesDias.map((String dia1) {
                        return DropdownMenuItem<String>(
                          value: dia1,
                          child: Text(dia1),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          diaSeleccionado1 = nuevoValor;
                          diaSeleccionado2 = null;
                        });
                      },
                      validator: (value) => value == null ? 'Por favor, selecciona un día' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: diaSeleccionado2,
                      hint: Text("Día de fin del horario"),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                        hintText: 'Seleccione un día de fin del horario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      items: opcionesDias2.map((String dia2) {
                        return DropdownMenuItem<String>(
                          value: dia2,
                          child: Text(dia2),
                        );
                      }).toList(),
                      onChanged: diaSeleccionado1 == null ? null : (String? nuevoValor) {
                        setState(() {
                          diaSeleccionado2 = nuevoValor;
                        });
                      },
                      validator: (value) => value == null ? 'Por favor, selecciona día' : null,
                    ),
                  ),
                ],
              ),
                  SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(
                     child: DropdownButtonFormField<String?>(
                       value: horaSeleccionada1,
                       hint: Text("Hora de inicio del horario:"),
                       isExpanded: true,
                       decoration: InputDecoration(
                         contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                         hintText: 'Seleccione una hora de inicio del horario',
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(8.0),
                         ),
                       ),
                       items: opcionesHora.map((String hora1) {
                         return DropdownMenuItem<String>(
                           value: hora1,
                           child: Text(hora1),
                         );
                       }).toList(),
                       onChanged: (String? nuevoValor) {
                         setState(() {
                           horaSeleccionada1 = nuevoValor;
                           horaSeleccionada2 = null;
                         });
                       },
                       validator: (value) => value == null ? 'Por favor, selecciona una hora' : null,
                     ),
                   ),
                   SizedBox(width: 16),
                   Expanded(
                     child: DropdownButtonFormField<String?>(
                       value: horaSeleccionada2,
                       hint: Text("Hora de fin del horario:"),
                       isExpanded: true,
                       decoration: InputDecoration(
                         contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                         hintText: 'Seleccione una hora de fin del horario',
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(8.0),
                         ),
                       ),
                       items: opcionesHoras2.map((String hora2) {
                         return DropdownMenuItem<String>(
                           value: hora2,
                           child: Text(hora2),
                         );
                       }).toList(),
                       onChanged: horaSeleccionada1 == null ? null : (String? nuevoValor) {
                         setState(() {
                           horaSeleccionada2 = nuevoValor;
                         });
                       },
                       validator: (value) => value == null ? 'Por favor, selecciona una hora' : null,
                     ),
                   ),
                 ],
               ),
              SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.green[700]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'La ubicación exacta se determinará automáticamente a partir de la dirección proporcionada',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDireccionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dirección del punto *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _buildTextField(
          controller: _calleController,
          label: 'Calle',
          hintText: 'Ej: Avenida México',
          validator: (value) => value!.isEmpty ? 'Ingresa la calle' : null,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _numeroController,
                label: 'Número',
                hintText: 'Ej: 123',
                keyboardType: TextInputType.text,
                validator: (value) => value!.isEmpty ? 'Ingresa el número' : null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _coloniaController,
                label: 'Colonia',
                hintText: 'Ej: Centro',
                validator: (value) => value!.isEmpty ? 'Ingresa la colonia' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Mostrar indicador y botón de vista previa
        _buildPreviewSection(),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ciudad: Tepic, Nayarit, México',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final calle = _calleController.text.trim();
    final numero = _numeroController.text.trim();
    final colonia = _coloniaController.text.trim();
    final puedeValidar = calle.isNotEmpty && numero.isNotEmpty && colonia.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _direccionValida ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _direccionValida ? Colors.green[300]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botón para buscar dirección
          ElevatedButton.icon(
            onPressed: puedeValidar && !_geocodificandoPreview
                ? _buscarDireccion
                : null,
            icon: _geocodificandoPreview
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.search),
            label: Text(
              _geocodificandoPreview ? 'Buscando...' : 'Buscar Dirección',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey[400],
              minimumSize: Size(double.maxFinite, 40),
            ),
          ),
          if (_geocodificandoPreview) ...[
            SizedBox(height: 12),
            Text(
              'Verificando dirección...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
          if (_ubicacionPreview != null && _direccionValida) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Dirección geocodificada correctamente',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lat: ${_ubicacionPreview!.latitud.toStringAsFixed(4)}, '
                    'Lon: ${_ubicacionPreview!.longitud.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _mostrarMapaPreview,
                    icon: Icon(Icons.map, color: Colors.white),
                    label: Text(
                      'Ajustar en Mapa',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.maxFinite, 36),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_geocodificandoPreview && !puedeValidar) ...[
            SizedBox(height: 8),
            Text(
              'Completa los campos: Calle, Número y Colonia',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _buscarDireccion() async {
    final calle = _calleController.text.trim();
    final numero = _numeroController.text.trim();
    final colonia = _coloniaController.text.trim();

    if (calle.isEmpty || numero.isEmpty || colonia.isEmpty) {
      setState(() {
        _direccionValida = false;
        _ubicacionPreview = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor completa: Calle, Número y Colonia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _geocodificandoPreview = true;
    });

    try {
      final ubicacion = await _geocodingService.obtenerUbicacionPreview(
        calle: calle,
        numero: numero,
        colonia: colonia,
      );

      setState(() {
        _ubicacionPreview = ubicacion;
        _direccionValida = true;
        _geocodificandoPreview = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dirección encontrada. Puedes ajustarla en el mapa si lo deseas.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al geocodificar: $e');
      setState(() {
        _geocodificandoPreview = false;
        _direccionValida = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar la dirección: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarMapaPreview() {
    if (_ubicacionPreview == null) return;
    
    showDialog(
      context: context,
      builder: (context) => MapaUbicacionWidget(
        latitud: _ubicacionPreview!.latitud,
        longitud: _ubicacionPreview!.longitud,
        nombreUbicacion: _nombreController.text.isNotEmpty
            ? _nombreController.text
            : 'Punto de Reciclaje',
        onCerrar: () => Navigator.pop(context),
        onUbicacionActualizada: (lat, lon, direccion) {
          // Actualizar la preview con las nuevas coordenadas
          setState(() {
            _ubicacionPreview = UbicacionPreview(
              latitud: lat,
              longitud: lon,
              precision: 'ajustada-usuario',
            );
            
            // Si la dirección reverse trae componentes válidos, actualizar campos
            if (direccion != null && 
                direccion.calle != null && 
                direccion.calle!.isNotEmpty &&
                !direccion.calle!.contains('Desconocida') &&
                !direccion.calle!.contains('Error')) {
              
              // Solo actualizar si el componente tiene contenido significativo
              if (direccion.calle!.isNotEmpty) {
                _calleController.text = direccion.calle!;
              }
              if (direccion.numero != null && direccion.numero!.isNotEmpty) {
                _numeroController.text = direccion.numero!;
              }
              if (direccion.colonia != null && 
                  direccion.colonia!.isNotEmpty &&
                  !direccion.colonia!.contains('Desconocida')) {
                _coloniaController.text = direccion.colonia!;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dirección actualizada desde el mapa'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              // Si no hay dirección válida, solo mostrar que se actualizó la ubicación
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ubicación actualizada. Ingresa los datos de dirección manualmente.'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.amber,
                ),
              );
            }
          });
        },
      ),
    );
  }

  Widget _buildMaterialSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materiales que se reciclan *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Selecciona todos los materiales que acepta este punto:',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tiposMaterial.map((material) {
            return FilterChip(
              label: Text(material),
              selected: _tiposSeleccionados.contains(material),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _tiposSeleccionados.add(material);
                  } else {
                    _tiposSeleccionados.remove(material);
                  }
                });
              },
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green,
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
        if (_tiposSeleccionados.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selecciona al menos un tipo de material',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return _enviando
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _enviarSolicitud,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Enviar Solicitud',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );
  }

  void _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tiposSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona al menos un tipo de material')),
      );
      return;
    }

    setState(() {
      _enviando = true;
    });

    final direccion = Direccion(
      calle: _calleController.text,
      numero: _numeroController.text,
      colonia: _coloniaController.text,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    horario = '${diaSeleccionado1} a ${diaSeleccionado2} : ${horaSeleccionada1} - ${horaSeleccionada2}';
    final solicitud = SolicitudPunto(
      id: '',
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      direccion: direccion,
      tipoMaterial: _tiposSeleccionados,
      telefono: _telefonoController.text,
      horario: horario,
      usuarioSolicitante: authProvider.userName!, // Usar el nombre real del usuario
      estado: 'pendiente',
      fechaCreacion: DateTime.now(),
    );

    try {
      // Pasar la solicitud con los datos de autenticación del usuario
      final success = await _solicitudesService.crearSolicitud(
        solicitud,
        ubicacion: _ubicacionPreview != null ? {
          'latitud': _ubicacionPreview!.latitud,
          'longitud': _ubicacionPreview!.longitud,
        } : null,
        userName: authProvider.userName!,
        isAdmin: authProvider.isAdmin,
      );
      
      if (success) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Notifica al provider del usuario (como ya lo tienes)
        Provider.of<SolicitudesProvider>(context, listen: false)
            .cargarSolicitudesUsuario(authProvider.userName!, authProvider.isAdmin);

        // --- ¡LA PIEZA CLAVE! Notifica también al provider del admin ---
        Provider.of<AdminSolicitudesProvider>(context, listen: false)
            .cargarSolicitudesPendientes(authProvider.userName!, authProvider.isAdmin);

        Navigator.pop(context, true); // Regresar indicando éxito
      } else {
        throw Exception('Error al enviar la solicitud');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al enviar la solicitud: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _enviando = false;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _coloniaController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}