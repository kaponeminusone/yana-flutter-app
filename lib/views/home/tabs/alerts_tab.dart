// lib/views/home/tabs/alerts_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yana/utils/calendar_widget.dart'; // Mantener si se usa directamente
import 'dart:math' as math;

import 'package:yana/utils/google_calendar_widget.dart';

// Enum para los tipos de alerta (opcional, pero mejora la legibilidad y tipado)
enum AlertType {
  service,
  legal,
  maintenance,
  general,
}

// Clase para representar una alerta con más detalle
class AlertModel {
  final int id;
  final DateTime date;
  final String description;
  final String? plate; // Matrícula del vehículo asociado
  final AlertType type; // Tipo de alerta
  final bool isCompleted; // Para simular si la alerta ha sido atendida

  AlertModel({
    required this.id,
    required this.date,
    required this.description,
    this.plate,
    this.type = AlertType.general,
    this.isCompleted = false,
  });
}

class AlertsTab extends StatefulWidget {
  const AlertsTab({Key? key}) : super(key: key);

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  // Datos de ejemplo mejorados para alertas
  final List<AlertModel> allAlerts = <AlertModel>[
    AlertModel(
      id: 1,
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Revisión de frenos programada. Urgente.',
      plate: 'XYZ-123',
      type: AlertType.maintenance,
      isCompleted: false,
    ),
    AlertModel(
      id: 2,
      date: DateTime.now().add(const Duration(days: 0, hours: 2)), // Hoy, en 2 horas
      description: 'Renovar SOAT. Vence hoy.',
      plate: 'ABC-789',
      type: AlertType.legal,
      isCompleted: false,
    ),
    AlertModel(
      id: 3,
      date: DateTime.now().add(const Duration(days: 5)),
      description: 'Cambio de aceite y filtros. Próximo mantenimiento.',
      plate: 'MNO-456',
      type: AlertType.service,
      isCompleted: false,
    ),
    AlertModel(
      id: 4,
      date: DateTime.now().add(const Duration(days: 10)),
      description: 'Revisión Técnico-Mecánica. Programar cita.',
      plate: 'PQR-012',
      type: AlertType.legal,
      isCompleted: false,
    ),
    AlertModel(
      id: 5,
      date: DateTime.now().subtract(const Duration(days: 10)),
      description: 'Pago de impuestos vehiculares. Vencido.',
      plate: 'STU-345',
      type: AlertType.legal,
      isCompleted: true, // Simula que ya se atendió pero es antigua
    ),
    AlertModel(
      id: 6,
      date: DateTime.now().add(const Duration(days: 20)),
      description: 'Inspección general del vehículo. Viaje largo.',
      plate: 'VWX-678',
      type: AlertType.maintenance,
      isCompleted: false,
    ),
    AlertModel(
      id: 7,
      date: DateTime.now().add(const Duration(days: 1, hours: 10)), // Mañana
      description: 'Recordatorio: Reunión sobre seguros del vehículo. ',
      plate: null, // Alerta general sin placa específica
      type: AlertType.general,
      isCompleted: false,
    ),
    AlertModel(
      id: 8,
      date: DateTime.now().subtract(const Duration(days: 1)), // Ayer
      description: 'Lavar el auto. Estacionado al aire libre.',
      plate: 'ABC-789',
      type: AlertType.maintenance,
      isCompleted: true,
    ),
    AlertModel(
      id: 9,
      date: DateTime.now().add(const Duration(days: 30)),
      description: 'Revisión de niveles de fluidos y neumáticos.',
      plate: 'XYZ-123',
      type: AlertType.maintenance,
      isCompleted: false,
    ),
    AlertModel(
      id: 10,
      date: DateTime.now().add(const Duration(days: 45)),
      description:
          'Considerar cambio de llantas. Vida útil cercana a su fin. Esta es una descripción más larga para ver cómo se maneja el texto dentro del preview y en la lista de alertas.',
      plate: 'MNO-456',
      type: AlertType.service,
      isCompleted: false,
    ),
    AlertModel(
      id: 11,
      date: DateTime.now().add(const Duration(days: 60)),
      description: 'Próximo vencimiento de la licencia de conducción.',
      plate: null, // Alerta personal
      type: AlertType.legal,
      isCompleted: false,
    ),
  ];

  // Filtros
  DateTime? _filterDate;
  String? _filterDesc;
  String? _filterPlate;

  late List<AlertModel> _filteredAlerts;
  AlertModel? _selectedAlert;

  bool _isPreviewExpanded = false;

  final double _previewMinHeight = 100.0;
  double _previewMaxHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _applyFilters(); // Aplicar filtros iniciales
    // Seleccionar la primera alerta si existe
    _selectedAlert = _filteredAlerts.isNotEmpty ? _filteredAlerts.first : null;
  }

  void _applyFilters() {
    setState(() {
      _filteredAlerts = allAlerts.where((a) {
        final matchDate = _filterDate == null ||
            (a.date.year == _filterDate!.year &&
                a.date.month == _filterDate!.month &&
                a.date.day == _filterDate!.day);
        final matchDesc = _filterDesc == null ||
            a.description.toLowerCase().contains(_filterDesc!.toLowerCase());
        final matchPlate = _filterPlate == null ||
            (a.plate ?? '')
                .toLowerCase()
                .contains(_filterPlate!.toLowerCase());
        return matchDate && matchDesc && matchPlate;
      }).toList();

      // Ordenar alertas: primero las de hoy, luego las futuras por fecha, luego las pasadas por fecha (más recientes primero)
      _filteredAlerts.sort((a, b) {
        final today = DateTime.now();
        final aIsToday = a.date.year == today.year && a.date.month == today.month && a.date.day == today.day;
        final bIsToday = b.date.year == today.year && b.date.month == today.month && b.date.day == today.day;

        if (aIsToday && !bIsToday) return -1;
        if (!aIsToday && bIsToday) return 1;

        final aIsFuture = a.date.isAfter(today);
        final bIsFuture = b.date.isAfter(today);

        if (aIsFuture && !bIsFuture) return -1;
        if (!aIsFuture && bIsFuture) return 1;

        return a.date.compareTo(b.date);
      });

      // Si la alerta seleccionada ya no está en la lista filtrada, selecciona la primera de las filtradas
      if (_selectedAlert != null && !_filteredAlerts.any((a) => a.id == _selectedAlert!.id)) {
        _selectedAlert = _filteredAlerts.isNotEmpty ? _filteredAlerts.first : null;
      } else if (_selectedAlert == null && _filteredAlerts.isNotEmpty) {
        _selectedAlert = _filteredAlerts.first;
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // 5 años atrás
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 años adelante
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // Usa el color principal del tema para el picker
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      _filterDate = d;
      _applyFilters();
    }
  }

  void _clearDate() {
    _filterDate = null;
    _applyFilters();
  }

  // Helper para obtener el icono según el tipo de alerta
  IconData _getAlertTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.service:
        return Icons.build; // Un icono de llave inglesa para servicio
      case AlertType.legal:
        return Icons.gavel; // Un icono de martillo para legal
      case AlertType.maintenance:
        return Icons.car_repair; // Un icono de coche en reparación
      case AlertType.general:
      default:
        return Icons.notifications; // Icono general de notificación
    }
  }

  // Helper para obtener el color de la fecha
  Color _getDateColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertDate = DateTime(date.year, date.month, date.day);

    if (alertDate.isAtSameMomentAs(today)) {
      return Colors.orange.shade700; // Hoy
    } else if (alertDate.isBefore(today)) {
      return Colors.red.shade700; // Pasado/Vencido
    } else {
      return Theme.of(context).colorScheme.primary; // Futuro, usando el azul principal
    }
  }

  @override
  Widget build(BuildContext context) {
    _previewMaxHeight = MediaQuery.of(context).size.height / 3.0;

    if (_selectedAlert == null && _filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No hay alertas para mostrar.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Ajusta los filtros o espera nuevas notificaciones.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // 1. Calendario
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GoogleCalendarWidget(
              calendarUrl:
                  'https://calendar.google.com/calendar/embed'
                  '?src=8ae8cb2a1575ded2ee221185c6e5e79f32472a5fb9e46dbfd200992707995ddc@group.calendar.google.com'
                  '&ctz=America%2FBogota',
              height: MediaQuery.of(context).size.height * 0.4, // 40% de la pantalla
            ),
          ),
        ),

        // 2. Preview expandible/colapsable de alerta seleccionada
        SliverPersistentHeader(
          pinned: true,
          delegate: _PreviewAlertDelegate(
            minHeight: _previewMinHeight,
            maxHeight: _isPreviewExpanded ? _previewMaxHeight : _previewMinHeight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPreviewExpanded = !_isPreviewExpanded;
                });
              },
              child: _selectedAlert != null
                  ? _buildPreview(_selectedAlert!, isExpanded: _isPreviewExpanded)
                  : Container(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05), // Tono de azul claro
                      alignment: Alignment.center,
                      child: Text('Selecciona una alerta para ver detalles',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary.withOpacity(0.7))),
                    ),
            ),
          ),
        ),

        // 3. Filtros persistentes
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeaderDelegate(
            minHeight: 60,
            maxHeight: 60,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
                    onPressed: _pickDate,
                  ),
                  Text(_filterDate == null
                      ? 'Fecha'
                      : DateFormat('dd/MM/yyyy').format(_filterDate!)),
                  if (_filterDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clearDate,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        isDense: true,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      onChanged: (v) {
                        _filterDesc = v.isEmpty ? null : v;
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Matrícula',
                        isDense: true,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      onChanged: (v) {
                        _filterPlate = v.isEmpty ? null : v;
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4. Lista de alertas
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final a = _filteredAlerts[i];
              final dateColor = _getDateColor(a.date);
              final isSelected = a == _selectedAlert;

              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      _selectedAlert = a;
                      _isPreviewExpanded = false; // Colapsar el preview al seleccionar una nueva alerta
                    }),
                    child: Container(
                      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Sección de Fecha y Hora
                          SizedBox(
                            width: 60, // Ancho fijo para la columna de fecha
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('dd').format(a.date),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: dateColor,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(a.date).toLowerCase(),
                                  style: TextStyle(fontSize: 12, color: dateColor),
                                ),
                                Text(
                                  DateFormat.Hm().format(a.date),
                                  style: TextStyle(fontSize: 12, color: dateColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Icono de Alerta
                          Icon(
                            _getAlertTypeIcon(a.type),
                            color: Theme.of(context).colorScheme.primary, // Usar el color principal del tema
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          // Descripción y Matrícula
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.description,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                                    color: a.isCompleted ? Colors.grey : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (a.plate != null)
                                  Text(
                                    'Vehículo: ${a.plate}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.visibility,
                                  color: Theme.of(context).colorScheme.primary, size: 20), // Azul principal
                            ),
                          if (a.isCompleted)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16), // Divisor más elegante
                ],
              );
            },
            childCount: _filteredAlerts.length,
          ),
        ),
      ],
    );
  }

  // WIDGET DE PREVIEW MODIFICADO
  Widget _buildPreview(AlertModel a, {required bool isExpanded}) {
    final date = a.date;
    final dateColor = _getDateColor(date);
    final fullDateFmt = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'es').format(date);
    final timeFmt = DateFormat.Hm('es').format(date);

    Widget collapsedChild = Row(
      key: const ValueKey('collapsed'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Indicador visual de la fecha
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dateColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DETALLES DE LA ALERTA",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700], letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                a.description,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                  color: a.isCompleted ? Colors.grey : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (a.plate != null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              '${a.plate}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
      ],
    );

    Widget expandedChild = SingleChildScrollView( // Usamos SingleChildScrollView aquí para permitir el scroll del contenido completo
      key: const ValueKey('expanded'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ajustar el tamaño a su contenido
        children: [
          Row(
            children: [
              Icon(_getAlertTypeIcon(a.type), size: 28, color: Theme.of(context).colorScheme.primary), // Azul principal
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullDateFmt,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: dateColor,
                      )),
                  Text(timeFmt, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              decoration: a.isCompleted ? TextDecoration.lineThrough : null,
              color: a.isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          if (a.plate != null) ...[
            const SizedBox(height: 12),
            Text('Matrícula: ${a.plate}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)), // Usar un color secundario si hay, o un gris oscuro
          ],
          if (a.isCompleted) ...[
            const SizedBox(height: 8),
            Text('Alerta Completada', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );

    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05), // Tono de azul claro
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.topRight, // Alineamos el stack al top-right para la flecha
        children: [
          // Transición suave entre los dos contenidos
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition( // Añadir SizeTransition para un efecto de expansión/contracción suave
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                ),
              );
            },
            child: isExpanded ? expandedChild : collapsedChild,
          ),
          // Ícono de flecha que rota con animación
          Positioned(
            top: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isExpanded ? math.pi : 0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value,
                  child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary), // Azul principal
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Delegado para preview expandible
class _PreviewAlertDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight, maxHeight;
  final Widget child;

  _PreviewAlertDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(minHeight, maxHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _PreviewAlertDelegate old) =>
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      old.child != child;
}

// Delegado reutilizable para headers fijos
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight, maxHeight;
  final Widget child;

  _HeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      old.child != child;
}