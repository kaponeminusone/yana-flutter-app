// lib/views/vehicles/add_vehicle_view.dart
import 'package:flutter/material.dart';

class AddVehicleView extends StatefulWidget {
  const AddVehicleView({Key? key}) : super(key: key);

  @override
  State<AddVehicleView> createState() => _AddVehicleViewState();
}

class _AddVehicleViewState extends State<AddVehicleView> {
  int _currentStep = 0;

  // Datos básicos
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

  // Estado de documentos: fecha + archivo
  DateTime? _soatExpiry;
  String? _soatFile;
  DateTime? _propiedadExpiry;
  String? _propiedadFile;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  List<Step> get _steps => [
        Step(
          title: const Text('Datos'),
          content: Column(
            children: [
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
            ],
          ),
          isActive: _currentStep >= 0,
          state: _stepState(0),
        ),

        Step(
          title: const Text('Documentos'),
          content: Column(
            children: [
              _buildDocTile(
                label: 'SOAT',
                date: _soatExpiry,
                fileName: _soatFile,
                onPickDate: (d) => setState(() => _soatExpiry = d),
                onPickFile: () {
                  // aquí abrirías tu FilePicker
                  setState(() => _soatFile = 'soat_poliza.pdf');
                },
              ),
              const SizedBox(height: 12),
              _buildDocTile(
                label: 'Propiedad',
                date: _propiedadExpiry,
                fileName: _propiedadFile,
                onPickDate: (d) => setState(() => _propiedadExpiry = d),
                onPickFile: () {
                  setState(() => _propiedadFile = 'propiedad_documento.pdf');
                },
              ),
            ],
          ),
          isActive: _currentStep >= 1,
          state: _stepState(1),
        ),

        Step(
          title: const Text('Resumen'),
          content: _buildSummary(),
          isActive: _currentStep >= 2,
          state: _stepState(2),
        ),
      ];

  StepState _stepState(int i) {
    if (_currentStep == i) return StepState.editing;
    if (_currentStep > i) return StepState.complete;
    return StepState.indexed;
  }

  Widget _buildDocTile({
    required String label,
    required DateTime? date,
    required String? fileName,
    required ValueChanged<DateTime> onPickDate,
    required VoidCallback onPickFile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: Text(
            date != null
                ? '${date.day}/${date.month}/${date.year}'
                : 'Seleccionar fecha',
          ),
          onTap: () async {
            final today = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? today,
              firstDate: today.subtract(const Duration(days: 365)),
              lastDate: today.add(const Duration(days: 365 * 5)),
            );
            if (picked != null) onPickDate(picked);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.attach_file),
          title: Text(fileName ?? 'Seleccionar archivo'),
          onTap: onPickFile,
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Marca: ${_brandController.text}'),
        Text('Modelo: ${_modelController.text}'),
        const SizedBox(height: 8),
        Text('SOAT: '
            '${_soatExpiry != null ? '${_soatExpiry!.day}/${_soatExpiry!.month}/${_soatExpiry!.year}' : '-'} | '
            '${_soatFile ?? '-'}'),
        const SizedBox(height: 4),
        Text('Propiedad: '
            '${_propiedadExpiry != null ? '${_propiedadExpiry!.day}/${_propiedadExpiry!.month}/${_propiedadExpiry!.year}' : '-'} | '
            '${_propiedadFile ?? '-'}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Y', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: _currentStep,
        steps: _steps,
        onStepContinue: () {
          if (_currentStep < _steps.length - 1) {
            setState(() => _currentStep++);
          } else {
            // TODO: enviar datos al backend
            Navigator.of(context).pop();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.of(context).pop();
          }
        },
        controlsBuilder: (ctx, details) {
          final isLast = _currentStep == _steps.length - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLast ? 'Confirmar' : 'Siguiente'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Atrás'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
