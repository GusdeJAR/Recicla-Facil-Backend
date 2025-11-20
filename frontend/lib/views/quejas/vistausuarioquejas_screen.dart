// En un nuevo archivo: screens/vista_usuario_quejas.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/queja.dart';
import '../../providers/auth_provider.dart';
import '../../services/queja_service.dart';
class VistaUsuarioQuejas extends StatefulWidget {
   const VistaUsuarioQuejas({super.key});

  @override
  State<VistaUsuarioQuejas> createState() => _VistaUsuarioQuejasState();
}

class _VistaUsuarioQuejasState extends State<VistaUsuarioQuejas> {
  late Future<List<Queja>> _misQuejasFuture;
  final QuejaService _quejaService = QuejaService();


  @override
  void initState() {
    super.initState();
    final QuejaService _ = QuejaService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.userEmail;

    if (userEmail != null) {

      _misQuejasFuture = _quejaService.obtenerMisQuejas(userEmail);
    } else {
      _misQuejasFuture = Future.error('No se pudo identificar el email del usuario.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Queja>>(
      future: _misQuejasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar tus quejas: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aún no has enviado ninguna queja o sugerencia.'));
        }

        final misQuejas = snapshot.data!;
        return ListView.builder(
          itemCount: misQuejas.length,
          itemBuilder: (ctx, index) {
            final queja = misQuejas[index];
            return Card(
              margin:  EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                leading: Icon(
                  queja.estado == 'Pendiente' ? Icons.hourglass_top : Icons.check_circle,
                  color: queja.estado == 'Pendiente' ? Colors.orange : Colors.green,
                ),
                title: Text(queja.categoria, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(queja.mensaje),
                trailing: Text(queja.estado),
                onTap: (){
                  _mostrarVistaQueja(queja);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarVistaQueja(Queja q){
    showDialog(
      context: context,
      builder: (context) {
        final DateFormat formatter = DateFormat('dd/MM/yyyy - hh:mm a');

        return AlertDialog(
          title: Text('Detalles de la queja'),

          contentPadding: EdgeInsets.zero,

          content: Card(
            elevation: 0,
            margin: EdgeInsets.zero,

            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _construirInfoRenglon(
                    icon: Icons.category,
                    label: 'Categoría',
                    value: q.categoria,
                  ),
                  _construirInfoRenglon(
                    icon: Icons.message,
                    label: 'Mensaje',
                    value: q.mensaje,
                  ),
                  _construirInfoRenglon(
                    icon: q.estado == 'Pendiente' ? Icons.hourglass_top : Icons.check_circle,
                    label: 'Estado',
                    value: q.estado,
                    valueColor: q.estado == 'Pendiente' ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                  _construirInfoRenglon(
                    icon: Icons.calendar_today,
                    label: 'Fecha de creación',
                    value: formatter.format(q.fechaCreacion),
                  ),
                  if (q.respuestaAdmin != null && q.respuestaAdmin!.isNotEmpty)
                    _construirInfoRenglon(
                      icon: Icons.admin_panel_settings,
                      label: 'Respuesta del admin',
                      value: q.respuestaAdmin!,
                    ),
                  if (q.fechaAtencion != null)
                    _construirInfoRenglon(
                      icon: Icons.event_available,
                      label: 'Fecha de atención',
                      value: formatter.format(q.fechaAtencion!),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        );
      },
    );
  }

  Widget _construirInfoRenglon({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black54,
                    fontSize: 15,
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
