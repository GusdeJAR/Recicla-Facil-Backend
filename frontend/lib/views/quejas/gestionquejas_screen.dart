// En un nuevo archivo: screens/gestion_quejas_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rf_sprint1/views/quejas/vistadminquejas_screen.dart';
import 'package:rf_sprint1/views/quejas/vistausuarioquejas_screen.dart';
import '../../providers/auth_provider.dart';

class GestionQuejasScreen extends StatelessWidget {
   const GestionQuejasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el AuthProvider para obtener el rol del usuario
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial'),
        // Opcional: muestra un badge si es admin
        actions: [
          if (authProvider.isAdmin)
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Chip(
                label: Text('Admin', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            )
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Usamos el getter 'isAdmin' que creamos. ¡Es muy limpio!
          if (auth.isAdmin) {
            // Si es administrador, muestra la vista de administrador
            return VistaAdminQuejas();
          } else {
            // Si es un usuario normal, muestra su vista de quejas
            return VistaUsuarioQuejas();
          }
        },
      ),
    );
  }
}
