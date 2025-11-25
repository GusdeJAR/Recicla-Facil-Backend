import 'package:characters/characters.dart';
  // Normaliza texto para comparar categorías (sin acentos, espacios, mayúsculas)
  
// En un nuevo archivo: screens/vista_admin_quejas.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/queja_service.dart';
import '../../models/queja.dart';
class VistaAdminQuejas extends StatefulWidget {
   VistaAdminQuejas({super.key});

  @override
  State<VistaAdminQuejas> createState() => _VistaAdminQuejasState();
}

class _VistaAdminQuejasState extends State<VistaAdminQuejas> {
  int _tabIndex = 0;
  late Future<List<Queja>> _quejasFuture;
  final QuejaService _quejaService = QuejaService();
  bool _isActionLoading = false;
  String? _categoriaFiltro;
  final List<String> _categoriasDisponibles = [
     // La primera opción siempre será para ver todas las quejas.
     'Todas',
    // El resto de categorías que usas en tu formulario.
    'Sugerencia / Nueva funcionalidad',
    'Duda',
    'Reporte de falla técnica (error)',
    'Diseño y facilidad de uso',
    'Información sobre reciclaje',
    'Cuenta / Perfil',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _recargarQuejas();
  }
  String _normalize(String input) {
    final withNoSpaces = input.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final withNoAccents = withNoSpaces
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
    return withNoAccents;
  }

  void _recargarQuejas() {
    setState(() {
      final estadoBuscado = _tabIndex == 0 ? 'Pendiente' : 'Atendida';
      if (_categoriaFiltro == null || _categoriaFiltro == 'Todas') {
        // Obtener todas las quejas del estado seleccionado
        if (_tabIndex == 0) {
          _quejasFuture = _quejaService.obtenerQuejasPendientes();
        } else {
          _quejasFuture = _quejaService.obtenerQuejasAtendidas();
        }
      } else {
        // Obtener todas las quejas del estado y filtrar por categoría en frontend
        Future<List<Queja>> futureQuejas;
        if (_tabIndex == 0) {
          futureQuejas = _quejaService.obtenerQuejasPendientes();
        } else {
          futureQuejas = _quejaService.obtenerQuejasAtendidas();
        }
        _quejasFuture = futureQuejas.then((todas) {
          return todas.where((q) =>
            _normalize(q.categoria) == _normalize(_categoriaFiltro!)
          ).toList();
        });
      }
    });
  }

  void _mostrarSnackBar(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  void _atenderQueja(Queja queja) {
    final respuestaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final DateFormat formato = DateFormat('dd/MM/yyyy - hh:mm a');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(

          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          clipBehavior: Clip.antiAlias,
          content: SingleChildScrollView(
            child: Form( // Envolvemos todo en un Form para la validación
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.question_answer_outlined, color: Theme.of(context).primaryColor),
                        SizedBox(width: 12),
                        Text(
                          'Atender Queja',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la queja:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        SizedBox(height: 12),
                        _construirInfoSoloLectura(
                          icon: Icons.calendar_today,
                          label: 'Fecha de creación',
                          value: formato.format(queja.fechaCreacion),
                        ),
                        SizedBox(height: 12),
                        _construirInfoSoloLectura(
                          icon: Icons.message,
                          label: 'Mensaje del usuario',
                          value: queja.mensaje,
                        ),
                        Divider(height: 24, thickness: 0.8),

                        TextFormField(
                          controller: respuestaController,
                          decoration: InputDecoration(
                            labelText: 'Tu Respuesta *',
                            hintText: 'Escribe aquí la respuesta para el usuario...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: Icon(Icons.edit_note),
                          ),
                          maxLines: 4,
                          autofocus: true,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'La respuesta no puede estar vacía'
                              : null,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text('Cancelar'),
                          style: TextButton.styleFrom(

                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          child: Text('Enviar Respuesta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              if (_isActionLoading) return;
                              setState(() => _isActionLoading = true);
                              Navigator.of(dialogContext).pop();

                              try {
                                final resultado = await _quejaService.atenderQueja(
                                    queja.id, respuestaController.text);
                                if (mounted) {
                                  if (resultado['statusCode'] == 200) {
                                    _mostrarSnackBar('Queja atendida correctamente.');
                                    _recargarQuejas();
                                  } else {
                                    _mostrarSnackBar(
                                        resultado['mensaje'] ?? 'Error al atender la queja.',
                                        esError: true);
                                  }
                                }
                              } catch (e) {
                                if (mounted) _mostrarSnackBar(e.toString(), esError: true);
                              } finally {
                                if (mounted) setState(() => _isActionLoading = false);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirInfoSoloLectura({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
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
                    color: Colors.grey.shade800,
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
  // ==========================================================
  // LÓGICA PARA ELIMINAR QUEJA
  // ==========================================================
  void _eliminarQueja(String quejaId, String quejaCorreo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text('Confirmar Eliminación'),
        content:  Text('¿Estás seguro de que deseas eliminar esta queja escrita por ${quejaCorreo}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:  Text('No'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black
            ),
          ),
          // Botón rojo para confirmar la eliminación
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon:  Icon(Icons.warning),
            label:  Text('Sí, eliminar'),
            onPressed: () async {
              // Bloquea múltiples clics
              if (_isActionLoading) return;
              setState(() => _isActionLoading = true);

              // Cierra el diálogo
              Navigator.of(ctx).pop();

              try {
                final resultado = await _quejaService.eliminarQueja(quejaId);
                if (resultado['statusCode'] == 200) {
                  _mostrarSnackBar('Queja eliminada correctamente.');
                  _recargarQuejas(); // Actualiza la lista
                } else {
                  _mostrarSnackBar(
                      resultado['mensaje'] ?? 'Error al eliminar la queja.',
                      esError: true);
                }
              } catch (e) {
                _mostrarSnackBar(e.toString(), esError: true);
              } finally {
                setState(() => _isActionLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(8),
            isSelected: [_tabIndex == 0, _tabIndex == 1],
            onPressed: (int index) {
              setState(() {
                _tabIndex = index;
                if (_tabIndex == 0) {
                  _categoriaFiltro = 'Todas';
                } else {
                  _categoriaFiltro = null; // Para mostrar todas atendidas
                }
                _recargarQuejas();
              });
            },
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Pendientes'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Atendidas'),
              ),
            ],
          ),
        ),
        // --- WIDGET DEL FILTRO DE CATEGORÍAS ---
        Padding(
          padding:  EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: DropdownButtonFormField<String>(
            value: _categoriaFiltro ?? 'Todas',
            hint:  Text("Filtrar por categoría"),
            decoration:  InputDecoration(
              labelText: 'Filtro de categorías',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            isExpanded: true,
            items: _categoriasDisponibles.map((String categoria) {
              return DropdownMenuItem<String>(
                value: categoria,
                child: Text(
                  categoria,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (String? nuevoValor) {
              setState(() {
                _categoriaFiltro = nuevoValor;
                _recargarQuejas();
              });
            },
          ),
        ),

        // --- LISTA DE RESULTADOS DE QUEJAS ---
        // 'Expanded' es crucial para que la lista ocupe todo el espacio vertical
        // restante en la pantalla después del filtro.
        Expanded(
          child: Stack(
            children: [
              FutureBuilder<List<Queja>>(
                // El FutureBuilder ahora escucha a la variable genérica '_quejasFuture'.
                future: _quejasFuture,
                builder: (context, snapshot) {
                  // 1. Estado de Carga
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Muestra un loader solo si no hay una acción (atender/eliminar) ya en curso.
                    return _isActionLoading
                        ?  SizedBox.shrink()
                        :  Center(child: CircularProgressIndicator());
                  }

                  // 2. Estado de Error
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:  EdgeInsets.all(16.0),
                        child: Text(
                          'Error al cargar las quejas: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style:  TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  // 3. Estado de Sin Datos
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return  Center(
                      child: Text(
                        'No hay quejas que coincidan con el filtro seleccionado.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // 4. Estado Exitoso (Hay datos para mostrar)
                  final quejas = snapshot.data!;
                    return ListView.builder(
                      padding: EdgeInsets.only(top: 8.0),
                      itemCount: quejas.length,
                      itemBuilder: (ctx, index) {
                        final queja = quejas[index];
                        // Filtrar por estado según el tab seleccionado
                        if (_tabIndex == 0 && queja.estado != 'Pendiente') return SizedBox.shrink();
                        if (_tabIndex == 1 && queja.estado != 'Atendida') return SizedBox.shrink();
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                          elevation: 3,
                          child: ListTile(
                            title: Text(
                              '${queja.categoria} - (${queja.correo})',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(queja.mensaje, style: TextStyle(color: Colors.grey[700])),
                            ),
                            trailing: _tabIndex == 0
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.check_circle_outline, color: Colors.green),
                                        onPressed: () => _atenderQueja(queja),
                                        tooltip: 'Atender Queja',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _eliminarQueja(queja.id, queja.correo),
                                        tooltip: 'Eliminar Queja',
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                },
              ),

              // --- INDICADOR DE CARGA PARA ACCIONES (ATENDER/ELIMINAR) ---
              // Este widget se superpone a la lista cuando '_isActionLoading' es true.
              if (_isActionLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child:  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Procesando...',
                          style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
