// lib/views/home/tabs/maintenance_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/mantenimiento_provider.dart';
import '../../../models/mantenimiento_model.dart';

class MaintenanceTab extends StatefulWidget {
  const MaintenanceTab({Key? key}) : super(key: key);

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  DateTime? _filterDate;
  String? _filterType;
  String? _filterPlate;

  MantenimientoModel? _featuredMantenimiento;

  final TextEditingController _typeFilterController = TextEditingController();
  final TextEditingController _plateFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'es';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MantenimientoProvider>(context, listen: false).fetchMantenimientos();
    });
  }

  @override
  void dispose() {
    _typeFilterController.dispose();
    _plateFilterController.dispose();
    super.dispose();
  }

  List<MantenimientoModel> _applyFilters(List<MantenimientoModel> mantenimientos) {
    List<MantenimientoModel> filteredList = mantenimientos.where((mantenimiento) {
      final matchDate = _filterDate == null ||
          DateFormat.yMd().format(mantenimiento.fecha) == DateFormat.yMd().format(_filterDate!);

      final matchType =
          _filterType == null || mantenimiento.tipo.toLowerCase().contains(_filterType!.toLowerCase());

      final matchPlate = _filterPlate == null ||
          (mantenimiento.vehiculo?.placa?.toLowerCase() ?? '').contains(_filterPlate!.toLowerCase());

      return matchDate && matchType && matchPlate;
    }).toList();

    // Lógica para actualizar _featuredMantenimiento
    // Si _featuredMantenimiento actual no está en la lista filtrada,
    // o si es nulo y hay elementos en filteredList, asigna el primero.
    if (_featuredMantenimiento != null && !filteredList.contains(_featuredMantenimiento)) {
      _featuredMantenimiento = filteredList.isNotEmpty ? filteredList.first : null;
    } else if (_featuredMantenimiento == null && filteredList.isNotEmpty) {
      _featuredMantenimiento = filteredList.first;
    } else if (filteredList.isEmpty) {
      _featuredMantenimiento = null;
    }

    return filteredList;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _filterDate = d;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MantenimientoProvider>(
      builder: (context, mantenimientoProvider, child) {
        final List<MantenimientoModel> allMantenimientos = mantenimientoProvider.mantenimientos;
        final List<MantenimientoModel> filteredMantenimientos = _applyFilters(allMantenimientos);

        // Estado de carga inicial
        if (mantenimientoProvider.isLoading && allMantenimientos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Estado de error
        if (mantenimientoProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(
                  'Error: ${mantenimientoProvider.errorMessage}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    mantenimientoProvider.clearErrorMessage();
                    mantenimientoProvider.fetchMantenimientos();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Estado vacío
        if (allMantenimientos.isEmpty && !mantenimientoProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No tienes mantenimientos registrados.',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Usa el botón "+" para agregar uno.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        // Manejo del preview card y la lista
        return Column(
          children: [
            // PREVIEW CARD - Muestra solo si _featuredMantenimiento NO es nulo
            if (_featuredMantenimiento != null) // <-- ¡CAMBIO CLAVE AQUÍ!
              Container(
                margin: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                        child: Container(
                          width: 120,
                          color: Colors.grey.shade300,
                          // Si tienes una imagen de mantenimiento, podrías mostrarla aquí
                          child: const Center(child: Text('Preview')),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                // Usa el operador ?. para acceder de forma segura y ?? para un valor por defecto
                                _featuredMantenimiento!.tallerMecanico?.nombre ?? 'Taller Desconocido',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // La descripción no debería ser null si es requerida por el backend, pero se mantiene la precaución
                              Text(_featuredMantenimiento!.descripcion, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'Fecha: ${DateFormat('dd MMM - HH:mm', 'es').format(_featuredMantenimiento!.fecha)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Matrícula: ${_featuredMantenimiento!.vehiculo?.placa ?? 'N/A'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Obs: ${_featuredMantenimiento!.facturaPath != null ? 'Factura adjunta' : 'Sin factura'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else // Muestra un placeholder para el preview si _featuredMantenimiento es nulo
              Container(
                margin: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                height: 180, // Altura fija para el placeholder
                child: Center(
                  child: Text(
                    filteredMantenimientos.isEmpty
                        ? 'No hay mantenimientos para mostrar en el preview.'
                        : 'Selecciona un mantenimiento de la lista.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // FILTROS
            _buildFilterWidgets(context),

            const SizedBox(height: 12),

            // HISTORIAL - ListView
            Expanded(
              child: filteredMantenimientos.isEmpty
                  ? const Center(child: Text('No hay resultados para los filtros aplicados.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredMantenimientos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final mantenimiento = filteredMantenimientos[i];
                        final isFeatured = mantenimiento == _featuredMantenimiento;

                        final dateFmt = DateFormat('dd', 'es').format(mantenimiento.fecha);
                        final monthFmt = DateFormat('MMM', 'es').format(mantenimiento.fecha);
                        final timeFmt = DateFormat('HH:mm').format(mantenimiento.fecha);

                        return InkWell(
                          onTap: () => setState(() => _featuredMantenimiento = mantenimiento),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      dateFmt,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isFeatured ? Colors.red : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      monthFmt.toLowerCase(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(timeFmt, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const VerticalDivider(thickness: 1, width: 32),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    // Aquí también, maneja nulos para vehiculo?.placa
                                    mantenimiento.vehiculo?.placa ?? 'N/A',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    mantenimiento.tipo,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (isFeatured)
                                  const Icon(Icons.check, color: Colors.blue),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Implementar navegación a pantalla de edición.')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final bool confirm = await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirmar Eliminación'),
                                        content: const Text('¿Estás seguro de que quieres eliminar este mantenimiento?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm) {
                                      await mantenimientoProvider.deleteMantenimiento(mantenimiento.id);
                                      if (mantenimientoProvider.errorMessage == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Mantenimiento eliminado.')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al eliminar: ${mantenimientoProvider.errorMessage}')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterWidgets(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDate,
          ),
          Text(
            _filterDate == null
                ? 'Fecha'
                : DateFormat('dd/MM/yyyy').format(_filterDate!),
          ),
          if (_filterDate != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: _clearDateFilter,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _typeFilterController,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                isDense: true,
              ),
              onChanged: (v) {
                setState(() {
                  _filterType = v.isEmpty ? null : v;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _plateFilterController,
              decoration: const InputDecoration(
                labelText: 'Matrícula',
                isDense: true,
              ),
              onChanged: (v) {
                setState(() {
                  _filterPlate = v.isEmpty ? null : v;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}