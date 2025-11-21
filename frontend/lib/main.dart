import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rf_sprint1/providers/auth_provider.dart';
import 'package:rf_sprint1/providers/puntos_provider.dart';
import 'package:rf_sprint1/providers/solicitudes_provider.dart';
import 'package:rf_sprint1/views/contenido/contenido_tabs_screen.dart';
import 'package:rf_sprint1/views/forgot_password_screen.dart';

// Importa tus vistas y providers
import 'package:rf_sprint1/views/perfil/perfilUsuario_screen.dart';
import 'package:rf_sprint1/views/puntos/puntos_tabs_screen.dart';
import 'package:rf_sprint1/views/quejas/quejas_tabs_screen.dart';
import 'package:rf_sprint1/views/register_screen.dart';
import 'package:rf_sprint1/views/login_screen.dart';
import 'providers/admin_solicitudes_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // La instancia de AuthProvider se crea aquí, fuera del MaterialApp.
        // Ahora es persistente y no se reiniciará con las reconstrucciones de la UI.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PuntosProvider()),
        ChangeNotifierProvider(create: (_) => SolicitudesProvider()),
        ChangeNotifierProvider(create: (_) => AdminSolicitudesProvider()),
        // Si en el futuro necesitas otro provider, lo añadirías aquí:
        // ChangeNotifierProvider(create: (_) => QuejaProvider()),
      ],
      // El hijo ahora es el widget que CONSTRUYE la UI basándose en el estado.
      child: MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch para que el widget se reconstruya automáticamente
    // cuando el estado de autenticación cambie (ej. al hacer login/logout).
    final authProvider = context.watch<AuthProvider>();


    return MaterialApp(
      key: ValueKey(authProvider.isLoggedIn),
      title: 'RECICLAFÁCIL',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,

      // Si el usuario está logueado, muestra
      // HomeScreen. Si no, muestra LoginScreen. Como AuthProvider ya no se
      // reinicia, esta lógica es ahora estable y no causará el bug.
      home: authProvider.isLoggedIn ? HomeScreen() : LoginScreen(),

      // Define las rutas nombradas para una navegación limpia.
      routes: {
        // No necesitas una ruta para '/home' si la gestionas con la lógica de 'home:'.
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/profile': (context) => ProfileScreen(),
        '/quejas': (context) => QuejasTabsScreen(),
        '/contenido-educativo': (context) => ContenidoScreen(),
        '/puntos-reciclaje': (context) => PuntosTabsScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
      },
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<String> _pageTitles = [
    "Usuario",
    "Quejas y sugerencias",
    'Contenido educativo',
    'Puntos de reciclaje',
  ];

  void _onItemTapped(int index) {
    // First close the drawer synchronously, then update the state after the frame
    // to avoid changing the widget tree while pointer events are being processed
    // (this can trigger mouse-tracker assertions on web).
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = index;
      });
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return ProfileScreen();
      case 1:
        return QuejasTabsScreen();
      case 2:
        return ContenidoScreen();
      case 3:
        return PuntosTabsScreen();
      default:
        return ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_currentIndex]),
        backgroundColor: Colors.green,
        elevation: 4.0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: Icon(Icons.logout),
            onPressed: () => _confirmarCerrarSesion(context),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Menú de navegación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Usuario'),
              selected: _currentIndex == 0,
              selectedTileColor: Colors.green.withOpacity(0.1),
              selectedColor: Colors.green,
              onTap: () {
                _onItemTapped(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.subject),
              title: Text('Quejas y sugerencias'),
              selected: _currentIndex == 1,
              selectedTileColor: Colors.green.withOpacity(0.1),
              selectedColor: Colors.green,
              onTap: () {
                _onItemTapped(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Contenido educativo'),
              selected: _currentIndex == 2,
              selectedTileColor: Colors.green.withOpacity(0.1),
              selectedColor: Colors.green,
              onTap: () {
                _onItemTapped(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.pin_drop),
              title: Text('Puntos de reciclaje'),
              selected: _currentIndex == 3,
              selectedTileColor: Colors.green.withOpacity(0.1),
              selectedColor: Colors.green,
              onTap: () {
                _onItemTapped(3);
              },
            ),
          ],
        ),
      ),
      body: _buildCurrentPage(),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          clipBehavior: Clip.antiAlias,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Theme.of(context).primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Text(
                  '¿Estás seguro de que quieres cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text('Cancelar'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.black
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _hacerCerrarSesion(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _hacerCerrarSesion(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.cerrarSesion();
  }

}