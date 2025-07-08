// lib/views/maintenance/edit_maintenance_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart'; // Importado para MultipartFile
import 'package:image_picker/image_picker.dart'; // Importado para seleccionar imágenes/archivos

import 'package:yana/providers/auth_provider.dart';
import 'package:yana/providers/mantenimiento_provider.dart';
import 'package:yana/providers/vehiculo_provider.dart';
import 'package:yana/models/mantenimiento_model.dart';
import 'package:yana/models/vehiculo_model.dart'; // Importa VehiculoModel si lo usas directamente

class EditMaintenanceView extends StatefulWidget {
  final MantenimientoModel maintenance;

  const EditMaintenanceView({Key? key, required this.maintenance}) : super(key: key);

  @override
  State<EditMaintenanceView> createState() => _EditMaintenanceViewState();
}

class _EditMaintenanceViewState extends State<EditMaintenanceView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descripcionController;
  late final TextEditingController _tipoController;
  late final TextEditingController _costoController;
  late final TextEditingController _kilometrajeController;

  DateTime? _selectedMaintenanceDate;
  DateTime? _selectedNextMaintenanceDate;

  // NUEVOS CONTROLADORES PARA LOS CAMPOS DE FECHA
  late final TextEditingController _maintenanceDateController;
  late final TextEditingController _nextMaintenanceDateController;


  String? _selectedVehicleId;

  XFile? _selectedInvoiceXFile;
  String? _existingInvoiceUrl; // Si tu MantenimientoModel guarda la URL de la factura

  final List<String> _tiposMantenimiento = [
    'Preventivo', 'Correctivo', 'Inspección', 'Cambio de Aceite',
    'Frenos', 'Neumáticos', 'Eléctrico', 'Lavado/Detallado', 'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController(text: widget.maintenance.descripcion);
    _tipoController = TextEditingController(text: widget.maintenance.tipo);
    _costoController = TextEditingController(text: widget.maintenance.costo.toString());
    _kilometrajeController = TextEditingController(text: widget.maintenance.kilometraje.toString());

    _selectedMaintenanceDate = widget.maintenance.fecha;
    _selectedNextMaintenanceDate = widget.maintenance.fechaVencimiento;

    // Initialize date controllers
    _maintenanceDateController = TextEditingController(
      text: _selectedMaintenanceDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedMaintenanceDate!)
          : '',
    );
    _nextMaintenanceDateController = TextEditingController(
      text: _selectedNextMaintenanceDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedNextMaintenanceDate!)
          : '',
    );

    _selectedVehicleId = widget.maintenance.vehiculoId;

    // If your maintenance model has a URL for the invoice, initialize it here
    // _existingInvoiceUrl = widget.maintenance.facturaUrl; // Adjust according to your MantenimientoModel

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
    _maintenanceDateController.dispose(); // Dispose new date controller
    _nextMaintenanceDateController.dispose(); // Dispose new date controller
    super.dispose();
  }

  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      );

  Future<void> _pickDate(
      {required Function(DateTime) onDateTimeSelected,
      required TextEditingController controllerToUpdate, // New parameter for the controller
      DateTime? initialDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      onDateTimeSelected(picked);
      // UPDATE THE TEXT OF THE CONTROLLER WITH THE SELECTED DATE
      controllerToUpdate.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _pickInvoiceFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedInvoiceXFile = pickedFile;
        _existingInvoiceUrl = null; // Clear existing URL if a new file is selected
      });
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

    final Map<String, dynamic> data = {
      'vehiculoId': _selectedVehicleId,
      'tipo': _tipoController.text.trim(),
      'fecha': _selectedMaintenanceDate!.toIso8601String(),
      'kilometraje': int.tryParse(_kilometrajeController.text.trim()) ?? 0,
      'descripcion': _descripcionController.text.trim(),
      'costo': double.tryParse(_costoController.text.trim()) ?? 0.0,
      'fechaVencimiento': _selectedNextMaintenanceDate?.toIso8601String(),
    };

    MultipartFile? facturaMultipartFile;
    if (_selectedInvoiceXFile != null) {
      facturaMultipartFile = await MultipartFile.fromFile(
        _selectedInvoiceXFile!.path,
        filename: _selectedInvoiceXFile!.name,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await mantenimientoProv.updateMantenimiento(
        widget.maintenance.id,
        data,
        facturaFile: facturaMultipartFile,
      );
      Navigator.of(context).pop(); // Dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mantenimiento actualizado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Close the view
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar mantenimiento: ${mantenimientoProv.errorMessage ?? e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      mantenimientoProv.clearErrorMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingMantenimiento = context.watch<MantenimientoProvider>().isLoading;
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final vehicles = vehiculoProvider.vehiculos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mantenimiento'),
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

                  // CAMPO DE FECHA DE MANTENIMIENTO
                  GestureDetector(
                    onTap: () => _pickDate(
                      onDateTimeSelected: (date) {
                        setState(() {
                          _selectedMaintenanceDate = date;
                        });
                      },
                      initialDate: _selectedMaintenanceDate,
                      controllerToUpdate: _maintenanceDateController, // PASAR EL CONTROLADOR
                    ),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _maintenanceDateController, // ASIGNAR CONTROLADOR
                        decoration: InputDecoration(
                          labelText: 'Fecha del Mantenimiento',
                          border: _inputBorder(),
                          focusedBorder: _inputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CAMPO DE PRÓXIMO MANTENIMIENTO (OPCIONAL)
                  GestureDetector(
                    onTap: () => _pickDate(
                      onDateTimeSelected: (date) {
                        setState(() {
                          _selectedNextMaintenanceDate = date;
                        });
                      },
                      initialDate: _selectedNextMaintenanceDate ?? _selectedMaintenanceDate,
                      controllerToUpdate: _nextMaintenanceDateController, // PASAR EL CONTROLADOR
                    ),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _nextMaintenanceDateController, // ASIGNAR CONTROLADOR
                        decoration: InputDecoration(
                          labelText: 'Próximo Mantenimiento (Opcional)',
                          border: _inputBorder(),
                          focusedBorder: _inputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedNextMaintenanceDate = null;
                                _nextMaintenanceDateController.clear(); // LIMPIAR EL TEXTO DEL CONTROLADOR
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(
                      _selectedInvoiceXFile != null
                          ? 'Archivo seleccionado: ${_selectedInvoiceXFile!.name}'
                          : (_existingInvoiceUrl != null && _existingInvoiceUrl!.isNotEmpty
                                  ? 'Factura existente'
                                  : 'Seleccionar factura (Opcional)'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_existingInvoiceUrl != null && _existingInvoiceUrl!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Funcionalidad de ver factura no implementada.')),
                              );
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                          onPressed: _pickInvoiceFile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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
                        : const Text('Actualizar Mantenimiento', style: TextStyle(fontSize: 16)),
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