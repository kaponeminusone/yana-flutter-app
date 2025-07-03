// lib/views/maintenance/add_maintenance_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:yana/providers/auth_provider.dart';
import 'package:yana/providers/mantenimiento_provider.dart';
import 'package:yana/providers/vehiculo_provider.dart'; // Necesario para seleccionar el vehículo

class AddMaintenanceView extends StatefulWidget {
  const AddMaintenanceView({Key? key}) : super(key: key);

  @override
  State<AddMaintenanceView> createState() => _AddMaintenanceViewState();
}

class _AddMaintenanceViewState extends State<AddMaintenanceView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto del Mantenimiento
  final _descripcionController = TextEditingController();
  final _tipoController = TextEditingController();
  final _costoController = TextEditingController();
  final _kilometrajeController = TextEditingController();
  final _notasController = TextEditingController();

  // Se eliminan los controladores de taller ya que el endpoint del propietario no los usa directamente
  // final _tallerNombreController = TextEditingController();
  // final _tallerNitController = TextEditingController();

  // Campos para selecciones de fecha
  DateTime? _selectedMaintenanceDate;
  DateTime? _selectedNextMaintenanceDate;

  // Campo para el ID del vehículo seleccionado
  String? _selectedVehicleId;

  // Lista de tipos de mantenimiento predefinidos
  final List<String> _tiposMantenimiento = [
    'Preventivo',
    'Correctivo',
    'Inspección',
    'Cambio de Aceite',
    'Frenos',
    'Neumáticos',
    'Eléctrico',
    'Lavado/Detallado',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    // Cargar los vehículos al iniciar la vista para el selector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculoProvider>().fetchVehiculos();
    });
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _tipoController.dispose();
    _costoController.dispose();
    _kilometrajeController.dispose();
    _notasController.dispose();
    // Se eliminan los dispose de los controladores de taller
    // _tallerNombreController.dispose();
    // _tallerNitController.dispose();
    super.dispose();
  }

  // Estilo de borde para los TextFormField
  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      );

  // Función para mostrar el selector de fecha
  Future<void> _pickDate(
      {required Function(DateTime) onDateTimeSelected, DateTime? initialDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)), // Hasta 10 años en el futuro
    );
    if (picked != null) {
      onDateTimeSelected(picked);
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final mantenimientoProv = context.read<MantenimientoProvider>();

    if (!_formKey.currentState!.validate()) return;

    if (!auth.isAuthenticated || auth.user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un vehículo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMaintenanceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona la fecha del mantenimiento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // AQUI ES EL CAMBIO CLAVE: Construir el payload SIN el objeto 'tallerMecanico' anidado
    // ni 'tallerMecanicoId', según la documentación de POST /api/mantenimientos para propietario.
    final Map<String, dynamic> data = {
      'vehiculoId': _selectedVehicleId,
      'tipo': _tipoController.text.trim(),
      'fecha': _selectedMaintenanceDate!.toIso8601String(),
      'kilometraje': int.tryParse(_kilometrajeController.text.trim()) ?? 0,
      'descripcion': _descripcionController.text.trim(),
      'costo': double.tryParse(_costoController.text.trim()) ?? 0.0,
      'fechaProximoMantenimiento': _selectedNextMaintenanceDate?.toIso8601String(),
      // 'facturaPath': null, // Esto se manejaría con una carga de archivo real (multipart/form-data)
    };

    // Añadir 'notas' solo si no está vacío, ya que es opcional y podría ser null en el backend.
    if (_notasController.text.trim().isNotEmpty) {
      data['notas'] = _notasController.text.trim();
    }
    // Si 'notas' es un campo de texto simple en tu modelo de backend que siempre es String (no String?),
    // entonces deberías enviarlo siempre, incluso si es vacío:
    // data['notas'] = _notasController.text.trim();


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await mantenimientoProv.createMantenimiento(data);
      Navigator.of(context).pop(); // Quita el loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mantenimiento agregado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Cierra la vista
    } catch (e) {
      Navigator.of(context).pop(); // Quita el loading en caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar mantenimiento: ${mantenimientoProv.errorMessage ?? e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      mantenimientoProv.clearErrorMessage(); // Limpia cualquier mensaje de error anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingMantenimiento = context.watch<MantenimientoProvider>().isLoading;
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final vehicles = vehiculoProvider.vehiculos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Mantenimiento'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de Vehículo
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Vehículo',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    value: _selectedVehicleId,
                    hint: const Text('Selecciona un vehículo'),
                    items: vehicles.map((vehiculo) {
                      return DropdownMenuItem<String>(
                        value: vehiculo.id,
                        child: Text('${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.placa})'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVehicleId = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'Selecciona un vehículo' : null,
                  ),
                  const SizedBox(height: 16),

                  // Fecha del Mantenimiento
                  GestureDetector(
                    onTap: () => _pickDate(
                      onDateTimeSelected: (date) {
                        setState(() {
                          _selectedMaintenanceDate = date;
                        });
                      },
                      initialDate: _selectedMaintenanceDate,
                    ),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Fecha del Mantenimiento',
                          hintText: _selectedMaintenanceDate == null
                              ? 'Selecciona la fecha'
                              : DateFormat('dd/MM/yyyy').format(_selectedMaintenanceDate!),
                          border: _inputBorder(),
                          focusedBorder: _inputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        validator: (v) => _selectedMaintenanceDate == null ? 'Obligatorio' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fecha Próximo Mantenimiento (Opcional)
                  GestureDetector(
                    onTap: () => _pickDate(
                      onDateTimeSelected: (date) {
                        setState(() {
                          _selectedNextMaintenanceDate = date;
                        });
                      },
                      initialDate: _selectedNextMaintenanceDate ?? _selectedMaintenanceDate,
                    ),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Próximo Mantenimiento (Opcional)',
                          hintText: _selectedNextMaintenanceDate == null
                              ? 'Selecciona la fecha (opcional)'
                              : DateFormat('dd/MM/yyyy').format(_selectedNextMaintenanceDate!),
                          border: _inputBorder(),
                          focusedBorder: _inputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedNextMaintenanceDate = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tipo de Mantenimiento
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Tipo de Mantenimiento',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    value: _tipoController.text.isNotEmpty ? _tipoController.text : null,
                    hint: const Text('Selecciona el tipo'),
                    items: _tiposMantenimiento.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _tipoController.text = newValue ?? '';
                      });
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción del Trabajo',
                      hintText: 'Ej: Cambio de aceite, filtros y bujías',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Costo
                  TextFormField(
                    controller: _costoController,
                    decoration: InputDecoration(
                      labelText: 'Costo Total (USD)',
                      hintText: 'Ej: 75.50',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obligatorio';
                      final cost = double.tryParse(v);
                      if (cost == null || cost < 0) return 'Costo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kilometraje
                  TextFormField(
                    controller: _kilometrajeController,
                    decoration: InputDecoration(
                      labelText: 'Kilometraje en el Mantenimiento',
                      hintText: 'Ej: 50000',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                      suffixText: ' km',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obligatorio';
                      final km = int.tryParse(v);
                      if (km == null || km < 0) return 'Kilometraje inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notas (Opcional)
                  TextFormField(
                    controller: _notasController,
                    decoration: InputDecoration(
                      labelText: 'Notas Adicionales (Opcional)',
                      hintText: 'Detalles extra, piezas usadas, etc.',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Botón de Confirmar
                  ElevatedButton(
                    onPressed: isLoadingMantenimiento ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoadingMantenimiento
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar Mantenimiento', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}