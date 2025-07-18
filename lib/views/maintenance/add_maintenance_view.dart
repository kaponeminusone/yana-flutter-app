import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:dio/dio.dart'; // Importado para MultipartFile
import 'package:image_picker/image_picker.dart'; // Importado para seleccionar imágenes/archivos

import 'package:yana/providers/auth_provider.dart';
import 'package:yana/providers/mantenimiento_provider.dart';
import 'package:yana/providers/vehiculo_provider.dart';
// import 'package:yana/models/vehiculo_model.dart'; // No necesario si no se usa directamente

class AddMaintenanceView extends StatefulWidget {
  const AddMaintenanceView({Key? key}) : super(key: key);

  @override
  State<AddMaintenanceView> createState() => _AddMaintenanceViewState();
}

class _AddMaintenanceViewState extends State<AddMaintenanceView> {
  final _formKey = GlobalKey<FormState>();

  final _descripcionController = TextEditingController();
  final _tipoController = TextEditingController();
  final _costoController = TextEditingController();
  final _kilometrajeController = TextEditingController();

  DateTime? _selectedMaintenanceDate;
  DateTime? _selectedNextMaintenanceDate;

  // NUEVOS CONTROLADORES PARA LOS CAMPOS DE FECHA
  final TextEditingController _maintenanceDateController = TextEditingController();
  final TextEditingController _nextMaintenanceDateController = TextEditingController();


  String? _selectedVehicleId;
  XFile? _selectedInvoiceXFile;

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
    // DISPONER LOS NUEVOS CONTROLADORES
    _maintenanceDateController.dispose();
    _nextMaintenanceDateController.dispose();
    super.dispose();
  }

  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      );

  Future<void> _pickDate(
      {required Function(DateTime) onDateTimeSelected,
      required TextEditingController controllerToUpdate, // Nuevo parámetro para el controlador
      DateTime? initialDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      onDateTimeSelected(picked);
      // ACTUALIZAR EL TEXTO DEL CONTROLADOR CON LA FECHA SELECCIONADA
      controllerToUpdate.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _pickInvoiceFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedInvoiceXFile = pickedFile;
      });
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final mantenimientoProv = context.read<MantenimientoProvider>();

    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Formulario no válido.'); // DEBUG
      return;
    }

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

    // Validación de fecha de mantenimiento
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
      // 'fechaVencimiento' puede ser null, lo cual es manejado
      'fechaVencimiento': _selectedNextMaintenanceDate?.toIso8601String(),
    };

    print('DEBUG: Datos a enviar: $data'); // DEBUG

    MultipartFile? facturaMultipartFile;
    if (_selectedInvoiceXFile != null) {
      facturaMultipartFile = await MultipartFile.fromFile(
        _selectedInvoiceXFile!.path,
        filename: _selectedInvoiceXFile!.name,
      );
      print('DEBUG: Archivo de factura seleccionado: ${_selectedInvoiceXFile!.name}'); // DEBUG
    } else {
      print('DEBUG: No se seleccionó archivo de factura.'); // DEBUG
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await mantenimientoProv.createMantenimiento(data, facturaFile: facturaMultipartFile);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mantenimiento agregado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Cierra la vista de agregar mantenimiento
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el indicador de carga
      print('DEBUG: Error en createMantenimiento: $e'); // DEBUG
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar mantenimiento: ${mantenimientoProv.errorMessage ?? e.toString()}'),
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
                          // Ya no necesitas hintText dinámico aquí
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
                          // Ya no necesitas hintText dinámico aquí
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
                          : 'Seleccionar factura (Opcional)',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                      onPressed: _pickInvoiceFile,
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