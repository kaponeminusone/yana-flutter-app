// lib/views/home/tabs/alerts_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yana/utils/calendar_widget.dart';
import 'dart:math' as math; // Necesario para la animación de rotación del ícono

class AlertsTab extends StatefulWidget {
  const AlertsTab({Key? key}) : super(key: key);

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  // Datos de ejemplo para alertas
  final allAlerts = <Map<String, dynamic>>[
    ...List.generate(11, (i) {
      final now = DateTime.now().add(Duration(days: i - 5, hours: i * 3));
      return {
        'id': i,
        'date': now,
        'description': 'Alerta ${i + 1}: Servicio programado',
        'plate': i % 2 == 0 ? 'ABC-${1000 + i}' : null,
      };
    }),
    {
      'id': 99,
      'date': DateTime.now().add(const Duration(hours: 2)),
      'description': List.filled(
              10,
              'Esta es una descripción MUY larga para probar cómo se comporta el preview cuando el texto supera el doble de la altura normal del card. ')
          .join(),
      'plate': 'ZZZ-999',
    },
  ];

  // Filtros
  DateTime? _filterDate;
  String? _filterDesc;
  String? _filterPlate;

  late List<Map<String, dynamic>> _filtered;
  Map<String, dynamic>? _selected;

  // --- NUEVOS CAMBIOS ---
  // 1. Estado para controlar si el preview está expandido. Inicia minimizado.
  bool _isPreviewExpanded = false;

  // 2. Constante para la altura mínima del preview
  final double _previewMinHeight = 100.0;
  // La altura máxima se calculará en tiempo de ejecución.
  double _previewMaxHeight = 0.0;
  // --- FIN DE CAMBIOS ---

  @override
  void initState() {
    super.initState();
    _filtered = allAlerts;
    _selected = allAlerts.isNotEmpty ? allAlerts.first : null;
  }

  void _applyFilters() {
    setState(() {
      _filtered = allAlerts.where((a) {
        final date = a['date'] as DateTime;
        final matchDate = _filterDate == null ||
            DateFormat.yMd().format(date) ==
                DateFormat.yMd().format(_filterDate!);
        final matchDesc = _filterDesc == null ||
            a['description']
                .toString()
                .toLowerCase()
                .contains(_filterDesc!.toLowerCase());
        final matchPlate = _filterPlate == null ||
            (a['plate'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_filterPlate!.toLowerCase());
        return matchDate && matchDesc && matchPlate;
      }).toList();

      if (!_filtered.contains(_selected)) {
        _selected = _filtered.isNotEmpty ? _filtered.first : null;
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  @override
  Widget build(BuildContext context) {
    // --- NUEVO CÁLCULO DE ALTURA MÁXIMA ---
    // Calculamos 1/3 de la altura de la pantalla para la altura máxima del preview.
    _previewMaxHeight = MediaQuery.of(context).size.height / 3.0;
    // --- FIN DEL NUEVO CÁLCULO ---

    // Si no hay ninguna alerta seleccionada, mostramos un mensaje.
    if (_selected == null) {
      return const Center(child: Text("No hay alertas seleccionadas."));
    }
    final sel = _selected!;

    return CustomScrollView(
      slivers: [
        // 1. Calendario
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CalendarWidget(
              events: {
                DateTime.now(): ['Hoy'],
                DateTime.now().add(const Duration(days: 2)): ['Recordatorio'],
                DateTime.now().subtract(const Duration(days: 1)): ['Venció'],
              },
              initialDate: DateTime.now(),
              onDaySelected: (day) {
                setState(() {
                  _filterDate = day;
                  _applyFilters();
                });
              },
            ),
          ),
        ),

        // 2. Preview expandible/colapsable de alerta seleccionada
        SliverPersistentHeader(
          pinned: true,
          delegate: _PreviewAlertDelegate(
            minHeight: _previewMinHeight,
            // La altura máxima depende del estado de expansión
            maxHeight: _isPreviewExpanded ? _previewMaxHeight : _previewMinHeight,
            child: GestureDetector(
              // Añadimos el detector de toques para cambiar el estado
              onTap: () {
                setState(() {
                  _isPreviewExpanded = !_isPreviewExpanded;
                });
              },
              child: _buildPreview(sel, isExpanded: _isPreviewExpanded),
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
                    icon: const Icon(Icons.date_range),
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
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        isDense: true,
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
                      decoration: const InputDecoration(
                        labelText: 'Matrícula',
                        isDense: true,
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
              final a = _filtered[i];
              final date = a['date'] as DateTime;
              final isToday = DateFormat('yyyyMMdd').format(date) ==
                  DateFormat('yyyyMMdd').format(DateTime.now());
              final dFmt = DateFormat('dd', 'es').format(date);
              final mFmt = DateFormat('MMM', 'es').format(date);
              final tFmt = DateFormat.Hm('es').format(date);

              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selected = a),
                    child: Container(
                      color: a == _selected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                dFmt,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isToday ? Colors.red : Colors.black,
                                ),
                              ),
                              Text(
                                mFmt.toLowerCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                tFmt,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              a['description'],
                              style: const TextStyle(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (a['plate'] != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0),
                              child: Text(
                                a['plate'],
                                style:
                                    const TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ),
                          if (a == _selected)
                            const Padding(
                              padding:
                                  EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.visibility,
                                  color: Colors.blue, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
            childCount: _filtered.length,
          ),
        ),
      ],
    );
  }

  // --- WIDGET DE PREVIEW MODIFICADO ---
  Widget _buildPreview(Map<String, dynamic> a, {required bool isExpanded}) {
    final date = a['date'] as DateTime;
    final isToday = DateFormat('yyyyMMdd').format(date) ==
        DateFormat('yyyyMMdd').format(DateTime.now());
    final day = DateFormat('dd', 'es').format(date);
    final mon = DateFormat('MMM', 'es').format(date);
    final hr = DateFormat.Hm('es').format(date);

    // Contenido para el estado minimizado
    Widget collapsedChild = Row(
      key: const ValueKey('collapsed'),
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "VIENDO ALERTA",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700], letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                a['description'],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (a['plate'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                '${a['plate']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ),
      ],
    );

    // Contenido para el estado expandido
    Widget expandedChild = Column(
      key: const ValueKey('expanded'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.red : Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mon.toLowerCase(),
                    style: const TextStyle(fontSize: 14)),
                Text(hr, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Aquí no necesitamos Expanded ni Flexible si el padre tiene un tamaño fijo.
        // Usamos un Container con una altura definida para que el texto sepa cuánto espacio tiene.
        // Y dentro de él, el SingleChildScrollView para permitir el scroll.
        // El Expanded que tenías antes causaba el overflow.
        Expanded(
          // Utilizamos Expanded para que ocupe el espacio restante en el Column,
          // que ahora tiene una altura total definida por el SliverPersistentHeader.
          child: SingleChildScrollView(
            child: Text(
              a['description'],
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if ((a['plate'] as String?) != null) ...[
          const SizedBox(height: 12),
          Text('Matrícula: ${a['plate']}',
              style: const TextStyle(fontSize: 14)),
        ],
      ],
    );

    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Transición suave entre los dos contenidos
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: isExpanded ? expandedChild : collapsedChild,
          ),
          // Ícono de flecha que rota con animación
          Positioned(
            top: 0,
            right: -8, // Ajuste para alinear mejor el ícono
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isExpanded ? math.pi : 0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value,
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
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