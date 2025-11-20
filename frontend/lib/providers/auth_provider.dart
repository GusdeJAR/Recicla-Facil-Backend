// providers/auth_provider.dart
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _correoUsuario;
  String? _nombreUsuario;
  bool _esAdmin = false;
  bool _estaLogueado = false;

  // "Getters" públicos para acceder a los datos de forma segura
  String? get userEmail => _correoUsuario;
  String? get userName => _nombreUsuario;
  bool get isAdmin => _esAdmin;
  bool get isLoggedIn => _estaLogueado;

  // Método que se llamará después de un login exitoso
  Future <void> login(String email, String name, bool isAdmin) async{
    _correoUsuario = email;
    _nombreUsuario = name;
    _esAdmin = isAdmin;
    _estaLogueado = true;

    // Notifica a todos los widgets que están "escuchando" que hubo un cambio.
    notifyListeners();
  }

  // Método para cerrar sesión
  void cerrarSesion() {
    _correoUsuario = null;
    _nombreUsuario = null;
    _esAdmin = false;
    _estaLogueado = false;
    notifyListeners();
  }
}