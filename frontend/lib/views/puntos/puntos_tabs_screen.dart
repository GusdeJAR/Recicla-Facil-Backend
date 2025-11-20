import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rf_sprint1/views/puntos/admin_puntos_screen.dart';
import 'package:rf_sprint1/views/puntos/puntos_screen.dart';
import 'package:rf_sprint1/views/puntos/solicitudes_puntos_screen.dart';
import '../../providers/auth_provider.dart';

class PuntosTabsScreen extends StatefulWidget {
  const PuntosTabsScreen({super.key});

  @override
  State<PuntosTabsScreen> createState() => _QuejasTabsScreenState();
}

class _QuejasTabsScreenState extends State<PuntosTabsScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    List<Widget> pages;
    List<BottomNavigationBarItem> navBarItems;

    if (authProvider.isAdmin) {
      pages = [
        PuntosScreen(),
        AdminPuntosScreen(),
      ];
      navBarItems = [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Ver puntos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Gestionar puntos/solicitudes',
        ),
      ];
    } else {
      pages = [
        PuntosScreen(),
        SolicitudesPuntosScreen(),
      ];
      navBarItems = [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Ver puntos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit_document),
          label: 'Mis solicitudes',
        ),
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}