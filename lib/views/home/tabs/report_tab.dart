// lib/views/home/tabs/reports_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yana/models/reporte_model.dart';
import 'package:yana/providers/report_provider.dart';

/// `ReportsTab` displays a list of vehicle reports, including maintenance
/// and legal obligations. It supports filtering by various criteria
/// and provides a user-friendly interface for viewing and managing reports.
class ReportsTab extends StatefulWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  // Controllers for filter text fields (still needed for the placeholder filter form)
  final TextEditingController _mantenimientoTipoController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();

  // State variables for date and boolean filters
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool? _obligacionVigente; // null for 'all', true for 'current', false for 'expired'

  // Flag to indicate if manual filters have been applied (even if not functional)
  bool _manualFiltersApplied = false;

  @override
  void initState() {
    super.initState();
    // Fetch the automatic report when the widget is first initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAutomaticReport();
    });
  }

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    _mantenimientoTipoController.dispose();
    _placaController.dispose();
    _marcaController.dispose();
    super.dispose();
  }

  /// Fetches the automatic report from the `ReporteProvider`.
  Future<void> _fetchAutomaticReport() async {
    // Reset manual filter state when fetching automatic report
    setState(() {
      _manualFiltersApplied = false;
      _mantenimientoTipoController.clear();
      _placaController.clear();
      _marcaController.clear();
      _fechaInicio = null;
      _fechaFin = null;
      _obligacionVigente = null;
    });
    await context.read<ReporteProvider>().loadAutomatico();
  }

  /// This method is a placeholder for future manual filtering.
  /// It will not call the actual API for now.
  Future<void> _applyManualFiltersPlaceholder() async {
    // Set a flag to indicate that "filters" have been "applied"
    setState(() {
      _manualFiltersApplied = true;
      // You could potentially filter the existing automatic report data here
      // if you want to implement client-side filtering without new API calls.
      // For now, we'll just show the placeholder message.
    });
    // Do NOT call context.read<ReporteProvider>().loadManual() here
    // as per the requirement that it "no deberas llamar para la peticion ya que no funciona".
  }

  /// Displays a modal bottom sheet with filter options for reports.
  ///
  /// This method allows users to apply, clear, and modify filters.
  void _showFilterForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ensures the keyboard doesn't obscure fields
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filtrar Reportes (Funcionalidad Manual Deshabilitada)',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La búsqueda manual por filtros está deshabilitada temporalmente. Actualmente solo se muestra el reporte automático de su perfil.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // All filter fields are here but their action button will not trigger an API call.
                    TextField(
                      controller: _placaController,
                      decoration: const InputDecoration(
                        labelText: 'Placa del Vehículo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      enabled: false, // Disable interaction
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _marcaController,
                      decoration: const InputDecoration(
                        labelText: 'Marca del Vehículo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      enabled: false, // Disable interaction
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mantenimientoTipoController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Mantenimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.build),
                      ),
                      enabled: false, // Disable interaction
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerField(
                      context,
                      label: 'Fecha de Inicio Mantenimiento',
                      selectedDate: _fechaInicio,
                      onDateSelected: (date) {
                        setModalState(() {
                          _fechaInicio = date;
                        });
                      },
                      enabled: false, // Disable interaction
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerField(
                      context,
                      label: 'Fecha de Fin Mantenimiento',
                      selectedDate: _fechaFin,
                      onDateSelected: (date) {
                        setModalState(() {
                          _fechaFin = date;
                        });
                      },
                      enabled: false, // Disable interaction
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool?>(
                      decoration: const InputDecoration(
                        labelText: 'Estado Obligación Legal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment),
                      ),
                      value: _obligacionVigente,
                      items: const [
                        DropdownMenuItem<bool?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<bool?>(
                          value: true,
                          child: Text('Vigente'),
                        ),
                        DropdownMenuItem<bool?>(
                          value: false,
                          child: Text('Vencida'),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _obligacionVigente = value;
                        });
                      },
                      // This can remain enabled for UI interaction,
                      // but the "Aplicar Filtros" button will ignore it.
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Clear all filter fields and state variables.
                            _mantenimientoTipoController.clear();
                            _placaController.clear();
                            _marcaController.clear();
                            setState(() {
                              _fechaInicio = null;
                              _fechaFin = null;
                              _obligacionVigente = null;
                            });
                            _fetchAutomaticReport(); // Revert to automatic report
                            Navigator.pop(context);
                          },
                          child: const Text('Limpiar Filtros y Recargar Automático'),
                        ),
                        ElevatedButton(
                          // This button now only "simulates" applying filters
                          // but does not trigger a real API call.
                          onPressed: () {
                            _applyManualFiltersPlaceholder();
                            Navigator.pop(context); // Close bottom sheet.
                          },
                          child: const Text('Aplicar Filtros (Deshabilitado)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds a date picker form field.
  ///
  /// Allows users to select a date and updates the corresponding state variable.
  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onDateSelected,
    bool enabled = true, // Added enabled parameter
  }) {
    return InkWell(
      onTap: enabled
          ? () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null && pickedDate != selectedDate) {
                onDateSelected(pickedDate);
              }
            }
          : null, // Disable onTap if not enabled
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
          enabled: enabled, // Apply enabled state to decorator
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
              : 'Seleccionar fecha',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: enabled ? null : Theme.of(context).disabledColor, // Dim text if disabled
              ),
        ),
      ),
    );
  }

  /// Builds a title row for report sections (e.g., "Mantenimientos").
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Builds a message displayed when a section has no items.
  Widget _buildEmptySectionMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Text(
        message,
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
      ),
    );
  }

  /// Builds a single report item card.
  ///
  /// Displays vehicle information, maintenance records, and legal obligations.
  Widget _buildReportItem(ReporteItem r, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        // Optional: Navigate to a detailed view of the report if it exists.
        // print('Reporte seleccionado: ${r.placa}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: colorScheme.primary, size: 28),
                const SizedBox(width: 16),
                const SizedBox(
                  height: 40,
                  child: VerticalDivider(thickness: 1, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.marca} ${r.modelo}',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text('Placa: ${r.placa}', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                      if (r.nombrePropietario != null && r.nombrePropietario!.isNotEmpty)
                        Text('Propietario: ${r.nombrePropietario}',
                            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Mantenimientos', Icons.build),
            if (r.mantenimientos.isEmpty)
              _buildEmptySectionMessage('No hay mantenimientos registrados.'),
            ...r.mantenimientos.map((m) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.tipo,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '\$${m.precio.toStringAsFixed(0)}',
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${m.fecha})',
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Obligaciones Legales', Icons.assignment),
            if (r.obligacionesLegales.isEmpty)
              _buildEmptySectionMessage('No hay obligaciones legales registradas.'),
            ...r.obligacionesLegales.map((o) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        o.vigente ? Icons.check_circle_outline : Icons.error_outline,
                        color: o.vigente ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.nombreDocumento,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        o.vigente ? "Vigente" : "Vencida",
                        style: textTheme.bodySmall?.copyWith(
                            color: o.vigente ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Generates a list of example `ReporteItem` objects for demonstration purposes.
  List<ReporteItem> _fakeReporteItems() {
    return [
      ReporteItem.fromJson({
        "infoVehiculo": {"marca": "Toyota", "placa": "ABC123", "modelo": "Corolla", "color": "Blanco"},
        "infoPropietario": {"nombre": "Juan Pérez", "cedula": "12345678"},
        "mantenimientos": [
          {"tipo": "Cambio de aceite", "precio": 45000, "fecha": "2024-01-10"},
          {"tipo": "Rotación de llantas", "precio": 25000, "fecha": "2024-03-15"}
        ],
        "obligacionesLegales": [
          {"nombreDocumento": "SOAT", "vigente": true},
          {"nombreDocumento": "Revisión Técnico-Mecánica", "vigente": false}
        ]
      }),
      ReporteItem.fromJson({
        "infoVehiculo": {"marca": "Honda", "placa": "XYZ789", "modelo": "Civic", "color": "Rojo"},
        "infoPropietario": {"nombre": "Ana Gómez", "cedula": "87654321"},
        "mantenimientos": [
          {"tipo": "Revisión frenos", "precio": 120000, "fecha": "2024-02-20"}
        ],
        "obligacionesLegales": [
          {"nombreDocumento": "Impuesto Vehicular", "vigente": true}
        ]
      }),
      ReporteItem.fromJson({
        "infoVehiculo": {"marca": "Nissan", "placa": "PQR456", "modelo": "March", "color": "Gris"},
        "infoPropietario": null, // No owner for testing
        "mantenimientos": [], // No maintenance records
        "obligacionesLegales": [
          {"nombreDocumento": "SOAT", "vigente": true}
        ]
      }),
      ReporteItem.fromJson({
        "infoVehiculo": {"marca": "Ford", "placa": "MNO012", "modelo": "Explorer", "color": "Negro"},
        "infoPropietario": {"nombre": "Carlos", "cedula": "11223344"},
        "mantenimientos": [
          {"tipo": "Cambio de pastillas", "precio": 70000, "fecha": "2024-04-01"},
          {"tipo": "Alineación y balanceo", "precio": 40000, "fecha": "2024-05-10"}
        ],
        "obligacionesLegales": [
          {"nombreDocumento": "Seguro Todo Riesgo", "vigente": true}
        ]
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReporteProvider>();

    // Show a loading indicator while data is being fetched.
    if (reportProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasError = reportProvider.error != null;
    // Display actual items if no error and not showing placeholder for manual filters
    // Otherwise, show fake items if there's an error or if manual filters were "applied"
    // even if not functional.
    final items = (hasError || _manualFiltersApplied) ? _fakeReporteItems() : reportProvider.items;

    // Display a message when no reports are found and there's no error.
    if (items.isEmpty && !hasError && !_manualFiltersApplied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay reportes automáticos disponibles.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Asegúrate de tener un vehículo asociado a tu perfil o intenta recargar los datos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _fetchAutomaticReport(); // Reload only the automatic report.
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar Reporte Automático'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showFilterForm, // Still show the filter form
              icon: const Icon(Icons.filter_alt),
              label: const Text('Ver Filtros (Deshabilitado)'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchAutomaticReport, // Pull-to-refresh calls the automatic report
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
          slivers: [
            // Display error message if applicable.
            SliverToBoxAdapter(
              child: hasError
                  ? Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(
                        'Error al cargar reporte automático: ${reportProvider.error}. Mostrando información de ejemplo.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Message for when manual filters are "applied" (placeholder)
            SliverToBoxAdapter(
              child: _manualFiltersApplied
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'La funcionalidad de filtros manuales está deshabilitada temporalmente. Se muestra un reporte de ejemplo. Pulsa "Limpiar Filtros" para ver el reporte automático.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange[700], fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Display the list of reports.
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return Column(
                    children: [
                      _buildReportItem(item, context),
                      const Divider(height: 1), // Divider between items
                    ],
                  );
                },
                childCount: items.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterForm,
        tooltip: 'Ver Opciones de Filtro', // Changed tooltip
        child: const Icon(Icons.filter_alt),
      ),
    );
  }
}