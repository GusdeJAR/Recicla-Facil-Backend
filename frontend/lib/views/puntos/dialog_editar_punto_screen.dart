import 'package:flutter/material.dart';

import '../../models/punto_reciclaje.dart';
import '../../services/puntos_reciclaje_service.dart';
import '../../services/solicitudes_puntos_service.dart';
// Widget para el diálogo de edición. Es un StatefulWidget para manejar los controladores.
class DialogoEditarPunto extends StatefulWidget {
  final PuntoReciclaje punto;
  final VoidCallback onPuntoActualizado; // Función para notificar la actualización

  const DialogoEditarPunto({
    super.key,
    required this.punto,
    required this.onPuntoActualizado,
  });

  @override
  State<DialogoEditarPunto> createState() => _DialogoEditarPuntoState();
}

class _DialogoEditarPuntoState extends State<DialogoEditarPunto> {
  // Clave para identificar y validar nuestro formulario.
  final _formKey = GlobalKey<FormState>();
  final SolicitudesPuntosService _solicitudesService = SolicitudesPuntosService();

  // Usar la lista del servicio para mantener consistencia
  List<String> get _tiposMaterial => _solicitudesService.tiposMaterialDisponibles
      .where((material) => material != 'Todos') // Excluir "Todos" ya que es para filtros
      .toList();
  List<String> _tiposSeleccionados = [];
  // Controladores para cada campo del formulario.
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _telefonoController;
  late TextEditingController _horarioController;
  List <String> opcionesDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  List <String> opcionesHora = ['8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00', '11:30', '12:00',
    '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00',
        '18:30', '19:00'];
  String? diaSeleccionado1;
  String? diaSeleccionado2;
  String? horaSeleccionada1;
  String? horaSeleccionada2;
  String horario = "";
  bool _estaCargando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.punto.nombre);
    _descripcionController = TextEditingController(text: widget.punto.descripcion);
    _tiposSeleccionados = List<String>.from(widget.punto.tipoMaterial);
    final String telefonoLimpio = widget.punto.telefono.replaceAll(RegExp(r'\D'), '');
    String telefonoFormateado = telefonoLimpio;
    if (telefonoLimpio.length == 10) {
      telefonoFormateado =
          '${telefonoLimpio.substring(0, 3)} ' +
              '${telefonoLimpio.substring(3, 6)} ' +
              '${telefonoLimpio.substring(6, 10)}';
    }
    _telefonoController = TextEditingController(text: telefonoFormateado);
    _parsearHorarioInicial(widget.punto.horario);
    if (diaSeleccionado2 != null && !getOpcionesDias2().contains(diaSeleccionado2)) {
      diaSeleccionado2 = null;
    }
    if (horaSeleccionada2 != null && !getOpcionesHoras2().contains(horaSeleccionada2)) {
      horaSeleccionada2 = null;
    }
  }

  void _parsearHorarioInicial(String horarioString) {
    try {
      final indiceSeparador = horarioString.indexOf(':');

      if (indiceSeparador == -1) {
        print("Formato de horario inválido (falta ':').");
        return;
      }

      final parteDias = horarioString.substring(0, indiceSeparador).trim();
      final parteHoras = horarioString.substring(indiceSeparador + 1).trim();

      final dias = parteDias.split(' a ');
      final horas = parteHoras.split(' - ');

      diaSeleccionado1 = dias.isNotEmpty ? dias[0].trim() : null;
      diaSeleccionado2 = dias.length > 1 ? dias[1].trim() : null;

      horaSeleccionada1 = horas.isNotEmpty ? horas[0].trim() : null;
      horaSeleccionada2 = horas.length > 1 ? horas[1].trim() : null;

      if (diaSeleccionado1 != null && !opcionesDias.contains(diaSeleccionado1)) {
        diaSeleccionado1 = null;
      }
      if (diaSeleccionado2 != null && !opcionesDias.contains(diaSeleccionado2)) {
        diaSeleccionado2 = null;
      }
      if (horaSeleccionada1 != null && !opcionesHora.contains(horaSeleccionada1)) {
        horaSeleccionada1 = null;
      }
      if (horaSeleccionada2 != null && !opcionesHora.contains(horaSeleccionada2)) {
        horaSeleccionada2 = null;
      }

    } catch (e) {
      print("Error parseando el horario '$horarioString': $e. Se usarán valores por defecto.");
    }
  }

  List<String> getOpcionesDias2() {
    if (diaSeleccionado1 == null) return [];
    final int startIndex = opcionesDias.indexOf(diaSeleccionado1!);
    return startIndex == -1 ? [] : opcionesDias.sublist(startIndex + 1);
  }

  List<String> getOpcionesHoras2() {
    if (horaSeleccionada1 == null) return [];
    final int startIndex = opcionesHora.indexOf(horaSeleccionada1!);
    return startIndex == -1 ? [] : opcionesHora.sublist(startIndex + 1);
  }

  @override
  void dispose() {
    // Es importante desechar los controladores para liberar memoria.
    _nombreController.dispose();
    _descripcionController.dispose();
    _telefonoController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  // Función que se llama al presionar "Actualizar".
  Future<void> _submitForm() async {
    final esFormularioValido = _formKey.currentState?.validate() ?? false;
    final sonMaterialesValidos = _tiposSeleccionados.isNotEmpty;
    final String telefonoLimpio = _telefonoController.text.replaceAll(RegExp(r'\D'), '');
    if (esFormularioValido && sonMaterialesValidos) {
      setState(() => _estaCargando = true);

      final nuevoHorario = '${diaSeleccionado1 ?? ''} a ${diaSeleccionado2 ?? ''} : ${horaSeleccionada1 ?? ''} - ${horaSeleccionada2 ?? ''}';
      final bool exito = await PuntosReciclajeService.actualizarPuntoReciclaje(
        puntoId: widget.punto.id,
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        tipo_material: _tiposSeleccionados,
        telefono: telefonoLimpio,
        horario: nuevoHorario,
      );

      setState(() => _estaCargando = false);

      if (exito && mounted) {
        Navigator.of(context).pop();
        widget.onPuntoActualizado();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo actualizar el punto.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!sonMaterialesValidos) {
      // Si el formulario es válido pero no los materiales, forzamos una reconstrucción
      // para que se muestre el mensaje de error del selector de materiales.
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    final List<String> opcionesDias2 = getOpcionesDias2();
    final List<String> opcionesHoras2 = getOpcionesHoras2();
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      clipBehavior: Clip.antiAlias,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.edit_location_alt_outlined, color: Theme.of(context).primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'Editar punto de reciclaje',
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
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre *',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) => (value?.isEmpty ?? true) ? 'Este campo es obligatorio' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción *',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      maxLines: 2,
                      validator: (value) => (value?.isEmpty ?? true) ? 'Este campo es obligatorio' : null,
                    ),
                    SizedBox(height: 16),
                    _buildMaterialSelector(), // El selector de materiales se mantiene.
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isEmpty) return 'Ingresa un teléfono de contacto';
                          final String cleanValue = value.replaceAll(RegExp(r'\D'), '');
                          if (cleanValue.length < 10) {
                            return 'El número de teléfono debe ser de 10 dígitos (actual: ${cleanValue.length}).';
                          }
                          if (cleanValue.length > 10) {
                            return 'El número de teléfono no puede ser mayor a diez cifras (actual: ${cleanValue.length}).';
                          }
                          return null;
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
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _estaCargando ? null : () => Navigator.of(context).pop(),
                      child: Text('Cancelar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _estaCargando ? null : _submitForm,
                      child: _estaCargando
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
}
