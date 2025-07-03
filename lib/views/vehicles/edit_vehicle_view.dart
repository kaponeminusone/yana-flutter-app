// lib/views/vehicles/edit_vehicle_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yana/models/vehiculo_model.dart';
import 'package:yana/providers/vehiculo_provider.dart';

class EditVehicleView extends StatefulWidget {
  final VehiculoModel vehicle;
  const EditVehicleView({Key? key, required this.vehicle}) : super(key: key);

  @override
  State<EditVehicleView> createState() => _EditVehicleViewState();
}

class _EditVehicleViewState extends State<EditVehicleView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _yearController;
  late TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _placaController  = TextEditingController(text: v.placa);
    _marcaController  = TextEditingController(text: v.marca);
    _modeloController = TextEditingController(text: v.modelo);
    _yearController   = TextEditingController(text: v.year.toString());
    _colorController  = TextEditingController(text: v.color);
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vehProv = context.read<VehiculoProvider>();

    final data = {
      'placa': _placaController.text.trim(),
      'marca': _marcaController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'year': int.tryParse(_yearController.text.trim()) ?? 0,
      'color': _colorController.text.trim(),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await vehProv.updateVehiculo(widget.vehicle.id, data);
    Navigator.of(context).pop(); // cierra loading

    if (vehProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${vehProv.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
      vehProv.clearErrorMessage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo actualizado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // regresa al tab
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VehiculoProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Vehículo'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // -- MISMO FORMULARIO QUE EN ADD, PERO CON HINTS PRELLENOS --
                  TextFormField(
                    controller: _placaController,
                    decoration: InputDecoration(
                      labelText: 'Placa',
                      hintText: 'Ej: ${widget.vehicle.placa}',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _marcaController,
                    decoration: InputDecoration(
                      labelText: 'Marca',
                      hintText: 'Ej: ${widget.vehicle.marca}',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modeloController,
                    decoration: InputDecoration(
                      labelText: 'Modelo',
                      hintText: 'Ej: ${widget.vehicle.modelo}',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: 'Año',
                      hintText: 'Ej: ${widget.vehicle.year}',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obligatorio';
                      final y = int.tryParse(v);
                      if (y == null) return 'Número inválido';
                      if (y < 1900 || y > DateTime.now().year + 2) return 'Año fuera de rango';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _colorController,
                    decoration: InputDecoration(
                      labelText: 'Color',
                      hintText: 'Ej: ${widget.vehicle.color}',
                      border: _inputBorder(),
                      focusedBorder: _inputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
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
