import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/formulario_queja_widget.dart';
import 'gestionquejas_screen.dart';
import 'vistadminquejas_screen.dart';

class QuejasTabsScreen extends StatefulWidget {
  const QuejasTabsScreen({super.key});

  @override
  State<QuejasTabsScreen> createState() => _QuejasTabsScreenState();
}

class _QuejasTabsScreenState extends State<QuejasTabsScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    FormularioQuejaWidget(),
    GestionQuejasScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(

      body: authProvider.isAdmin ? VistaAdminQuejas() : IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: authProvider.isAdmin ? null : BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: 'Enviar mensaje',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: authProvider.isAdmin ? 'Gestionar quejas' : 'Mis mensajes',
          ),
        ],

        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
      ),

    );
  }

}