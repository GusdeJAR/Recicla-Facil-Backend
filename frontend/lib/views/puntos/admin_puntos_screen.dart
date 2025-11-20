// lib/views/admin_puntos_screen.dart

import 'package:flutter/material.dart';
import '../../providers/admin_solicitudes_provider.dart';
import '../../models/punto_reciclaje.dart';
import '../../models/solicitud_punto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/puntos_provider.dart';
import '../../services/solicitudes_puntos_service.dart';
import 'package:provider/provider.dart';
import 'dialog_editar_punto_screen.dart';

class AdminPuntosScreen extends StatefulWidget {
  const AdminPuntosScreen({super.key});

  @override
  State<AdminPuntosScreen> createState() => _AdminPuntosScreenState();
}

class _AdminPuntosScreenState extends State<AdminPuntosScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Llama al provider de puntos
      Provider.of<PuntosProvider>(context, listen: false).cargarPuntos();

      // Llama al NUEVO provider de solicitudes de admin
      Provider.of<AdminSolicitudesProvider>(context, listen: false)
          .cargarSolicitudesPendientes(authProvider.userName!, authProvider.isAdmin);
    });
  }

  Future<void> _cargarDatos() async {
    final authProvider = context.read<AuthProvider>();

    await Provider.of<PuntosProvider>(context, listen: false).cargarPuntos();
    await Provider.of<AdminSolicitudesProvider>(context, listen: false)
        .cargarSolicitudesPendientes(authProvider.userName!, authProvider.isAdmin);
  }

  // Lista de widgets que se mostrarán en el body
  List<Widget> _buildScreens(List <PuntoReciclaje> puntosGestion, List<SolicitudPunto> solicitudes) {
    return [
      _buildGestionarScreen(puntosGestion),
      _buildValidarScreen(solicitudes),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final puntosProvider = context.watch<PuntosProvider>();
    final adminSolicitudesProvider = context.watch<AdminSolicitudesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Gestionar puntos' : 'Validar solicitudes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.location_on,
              color: _selectedIndex == 0 ? Colors.green[700] : Colors.grey[500],
              size: 28,
            ),
            onPressed: () => _onItemTapped(0),
            tooltip: 'Gestionar',
          ),
          IconButton(
            icon: Icon(
              Icons.assignment_turned_in,
              color: _selectedIndex == 1 ? Colors.green[700] : Colors.grey[500],
              size: 28,
            ),
            onPressed: () => _onItemTapped(1),
            tooltip: 'Validar',
          ),
        ],
      ),
      body: adminSolicitudesProvider.isLoading ? Center (
        child: CircularProgressIndicator(),
      ): IndexedStack(
        index: _selectedIndex,
        children: _buildScreens(puntosProvider.puntos, adminSolicitudesProvider.solicitudesPendientes),
      ),
    );
  }

  // --- PANTALLA 1: GESTIONAR PUNTOS ---
  Widget _buildGestionarScreen(List <PuntoReciclaje> puntosGestion) {
    final puntosProvider = context.watch<PuntosProvider>();
    if (puntosProvider.isLoading && puntosGestion.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (puntosGestion.isEmpty) {
      return Center(child: Text('No hay puntos de reciclaje para gestionar.'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: puntosGestion.length,
      itemBuilder: (context, index) {
        final centro = puntosGestion[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(centro.nombre, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(centro.direccion, style: TextStyle(color: Colors.grey[700])),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.edit, size: 20),
                      label: Text('Editar'),
                      onPressed: () {
                        // TODO: Lógica para editar el centro
                        _editarPunto(context, centro);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(Icons.delete_outline, size: 20),
                      label: Text('Eliminar'),
                      onPressed: () async {
                        _eliminarPunto(centro.id, centro.nombre);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // lib/views/admin_puntos_screen.dart

  void _mostrarSnackBar(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }
  void _editarPunto(BuildContext context, PuntoReciclaje punto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DialogoEditarPunto(
          punto: punto,
          onPuntoActualizado: () {
              _cargarDatos();
              Provider.of<PuntosProvider>(context, listen: false).cargarPuntos();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Punto de reciclaje actualizado con éxito.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _aprobarSolicitud(SolicitudPunto solicitud) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.userName ?? '';
      final isAdmin = authProvider.isAdmin;

      final resultado = await SolicitudesPuntosService().aprobarSolicitud(
        solicitud.id,
        comentariosAdmin: 'Solicitud aprobada por el administrador',
        userName: userName,
        isAdmin: isAdmin,
      );

      if (mounted) {
        if (resultado) {
          _mostrarSnackBar('✓ Solicitud aprobada correctamente. El punto aparecerá en el mapa.');
          _cargarDatos();
          Provider.of<PuntosProvider>(context, listen: false).cargarPuntos();
        } else {
          _mostrarSnackBar('Error al aprobar la solicitud.', esError: true);
        }
      }
    } catch (e) {
      if (mounted) _mostrarSnackBar(e.toString(), esError: true);
    }
  }

  Widget _buildValidarScreen(List<SolicitudPunto> solicitudesPorValidar) {
    if (solicitudesPorValidar.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('¡Excelente! No hay solicitudes de puntos pendientes de validación.',
                textAlign: TextAlign.center),
          ));
    }

    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: solicitudesPorValidar.length,
      itemBuilder: (context, index) {
        final solicitud = solicitudesPorValidar[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade200, width: 1),
          ),
          color: Colors.orange[50],
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(solicitud.nombre,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87
                              )
                          ),
                          SizedBox(height: 4),
                          Text('Solicitado por: ${solicitud.usuarioSolicitante}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic
                              )
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pendiente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 20),

                _buildInfoRow(
                    Icons.location_on_outlined, 
                    'Dirección', 
                    '${solicitud.direccion.calle} ${solicitud.direccion.numero}, ${solicitud.direccion.colonia}'),

                _buildInfoRow(
                    Icons.description_outlined, 'Descripción', solicitud.descripcion),
                
                if (solicitud.tipoMaterial.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text('Materiales que acepta:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey[800]
                      )
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: solicitud.tipoMaterial.map((material) {
                      return Chip(
                        label: Text(material),
                        backgroundColor: Colors.green[100],
                        side: BorderSide.none,
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ],

                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.close),
                        label: Text('Rechazar'),
                        onPressed: () => _mostrarDialogoRechazo(solicitud),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Aceptar'),
                        onPressed: () => _aprobarSolicitud(solicitud),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// --- WIDGET AUXILIAR PARA MOSTRAR LA INFORMACIÓN ---
// Puedes poner este método dentro de la clase _AdminPuntosScreenState
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: Colors.black.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _eliminarPunto(String puntoId, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text('Confirmar Eliminación'),
        content:  Text('¿Estás seguro de que deseas eliminar el punto de ${nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:  Text('No'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon:  Icon(Icons.warning),
            label:  Text('Sí, Eliminar'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final puntosProvider = Provider.of<PuntosProvider>(context, listen: false);
                bool resultado = await puntosProvider.eliminarPunto(puntoId);
                if (resultado) {
                  _mostrarSnackBar('Punto eliminado correctamente.');
                  Provider.of<PuntosProvider>(context, listen: false).cargarPuntos();
                } else {
                  _mostrarSnackBar('Error al eliminar el punto.');
                }
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRechazo(SolicitudPunto solicitud) {
    final TextEditingController motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rechazar solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Punto: ${solicitud.nombre}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Motivo del rechazo:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                hintText: 'Ingresa el motivo del rechazo...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon: Icon(Icons.close),
            label: Text('Rechazar'),
            onPressed: () async {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text('Debes ingresar un motivo del rechazo')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _ejecutarRechazo(solicitud, motivoController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarRechazo(SolicitudPunto solicitud, String motivo) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.userName ?? '';
      final isAdmin = authProvider.isAdmin;

      final resultado = await SolicitudesPuntosService().rechazarSolicitud(
        solicitud.id,
        motivo,
        userName: userName,
        isAdmin: isAdmin,
      );

      if (mounted) {
        if (resultado) {
          _mostrarSnackBar('✗ Solicitud rechazada. El usuario recibirá una notificación.');
          _cargarDatos();
        } else {
          _mostrarSnackBar('Error al rechazar la solicitud.', esError: true);
        }
      }
    } catch (e) {
      if (mounted) _mostrarSnackBar(e.toString(), esError: true);
    }
  }
}
