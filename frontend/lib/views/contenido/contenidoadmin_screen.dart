import 'package:flutter/material.dart';
import 'package:rf_sprint1/views/contenido/contenidousuario_screen.dart';
import 'agregar_contenido_screen.dart';
import 'gestionar_contenido_screen.dart';

class ContenidoAdminScreen extends StatefulWidget {
  const ContenidoAdminScreen({super.key});

  @override
  State<ContenidoAdminScreen> createState() => _ContenidoAdminScreenState();
}

class _ContenidoAdminScreenState extends State<ContenidoAdminScreen> {
  int _paginaActual = 0;

  final List<Widget> _paginas = const [
    ContenidoUsuarioScreen(),
    AgregarContenidoScreen(),
    GestionarContenidoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple.shade50,
        currentIndex: _paginaActual,
        selectedItemColor: Colors.green,
        onTap: (index) => setState(() => _paginaActual = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Consultar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Gestionar',
          ),
        ],
      ),
    );
  }
}
