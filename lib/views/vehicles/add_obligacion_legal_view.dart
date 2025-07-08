// lib/views/vehicles/add_obligacion_legal_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import 'package:dio/dio.dart'; // Importado para MultipartFile
import 'package:file_picker/file_picker.dart'; // CAMBIO: Importado para seleccionar cualquier tipo de archivo

import 'package:yana/providers/auth_provider.dart';
import 'package:yana/providers/obligacion_legal_provider.dart';
import 'package:yana/providers/vehiculo_provider.dart';

class AddObligacionLegalView extends StatefulWidget {
  const AddObligacionLegalView({Key? key}) : super(key: key);

  @override
  State<AddObligacionLegalView> createState() => _AddObligacionLegalViewState();
}

class _AddObligacionLegalViewState extends State<AddObligacionLegalView> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _tipoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final TextEditingController _fechaVencimientoController = TextEditingController(); // Controlador para el texto de la fecha

  DateTime? _selectedFechaVencimiento;
  String? _selectedVehicleId;
  PlatformFile? _selectedDocumentFile; // CAMBIO: Usamos PlatformFile de file_picker

  final List<String> _tiposObligacion = [
    'Seguro Obligatorio (SOAT)',
    'Revisión Técnico Mecánica (RTM)',
    'Impuestos de Vehículo',
    'Licencia de Conducción',
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
    _nombreController.dispose();
    _tipoController.dispose();
    _descripcionController.dispose();
    _fechaVencimientoController.dispose(); // Disponer el controlador de fecha
    super.dispose();
  }

  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      );

  Future<void> _pickDate({
    required Function(DateTime) onDateTimeSelected,
    required TextEditingController controllerToUpdate,
    DateTime? initialDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)), // Fecha futura permitida
    );
    if (picked != null) {
      onDateTimeSelected(picked);
      controllerToUpdate.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // CAMBIO: Método para seleccionar archivo usando FilePicker
  Future<void> _pickDocumentFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // O puedes ser más específico, por ejemplo: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png']
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedDocumentFile = result.files.single; // Usa .single para un solo archivo
        });
      } else {
        // El usuario canceló la selección o no se seleccionó ningún archivo
        print('DEBUG: Selección de archivo cancelada o fallida.');
      }
    } catch (e) {
      print('DEBUG: Error al seleccionar archivo con FilePicker: $e');
      // Mostrar un SnackBar al usuario si hay un error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar el archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final obligacionLegalProv = context.read<ObligacionLegalProvider>();

    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Formulario no válido.');
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

    if (_selectedFechaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona la fecha de vencimiento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic> data = {
      'vehiculoId': _selectedVehicleId,
      'nombre': _nombreController.text.trim(),
      'tipo': _tipoController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'fechaVencimiento': _selectedFechaVencimiento!.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
    };

    print('DEBUG: Datos a enviar: $data');

    // CAMBIO: Obtener filePath de PlatformFile
    String? filePath;
    if (_selectedDocumentFile != null && _selectedDocumentFile!.path != null) {
      filePath = _selectedDocumentFile!.path;
      print('DEBUG: Archivo de documento seleccionado: ${_selectedDocumentFile!.name}');
    } else {
      print('DEBUG: No se seleccionó archivo de documento.');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // El servicio espera filePath, así que solo pasamos la ruta si existe
      await obligacionLegalProv.createObligacionLegal(data, filePath: filePath);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obligación legal agregada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Cierra la vista de agregar obligación
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el indicador de carga
      print('DEBUG: Error en createObligacionLegal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar obligación legal: ${obligacionLegalProv.errorMessage ?? e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      obligacionLegalProv.clearErrorMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingObligacion = context.watch<ObligacionLegalProvider>().isLoading;
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final vehicles = vehiculoProvider.vehiculos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Obligación Legal'),
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
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Obligación',
                      hintText: 'Ej: SOAT, Revisión Técnico Mecánica',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Tipo de Obligación',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    value: _tipoController.text.isNotEmpty ? _tipoController.text : null,
                    hint: const Text('Selecciona el tipo'),
                    items: _tiposObligacion.map((tipo) {
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
                      labelText: 'Descripción (Opcional)',
                      hintText: 'Ej: Póliza de seguro vigente',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _pickDate(
                      onDateTimeSelected: (date) {
                        setState(() {
                          _selectedFechaVencimiento = date;
                        });
                      },
                      initialDate: _selectedFechaVencimiento,
                      controllerToUpdate: _fechaVencimientoController,
                    ),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _fechaVencimientoController,
                        decoration: InputDecoration(
                          labelText: 'Fecha de Vencimiento',
                          border: _inputBorder(),
                          focusedBorder: _inputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CAMBIO: ListTile para seleccionar archivo (igual que en AddMaintenanceView)
                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(
                      _selectedDocumentFile != null
                          ? 'Archivo seleccionado: ${_selectedDocumentFile!.name}'
                          : 'Seleccionar documento (Opcional)',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                      onPressed: _pickDocumentFile, // Llama al nuevo método para FilePicker
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingObligacion ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoadingObligacion
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar Obligación Legal', style: TextStyle(fontSize: 16)),
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