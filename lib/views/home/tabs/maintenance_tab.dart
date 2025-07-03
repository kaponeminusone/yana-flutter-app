// lib/views/home/tabs/maintenance_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaintenanceTab extends StatefulWidget {
  const MaintenanceTab({Key? key}) : super(key: key);

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  // Datos de ejemplo
  final allRecords = List.generate(15, (i) {
    final now = DateTime.now().subtract(Duration(days: i * 3, minutes: i * 10));
    return {
      'id': i,
      'place': 'Taller ${i + 1}',
      'description': 'Cambio de aceite y revisión general.',
      'date': now,
      'plate': 'ABC-${1000 + i}',
      'observations': 'Se encontró ligera fuga en junta.',
      'type': i % 2 == 0 ? 'Preventivo' : 'Correctivo',
    };
  });

  // Estados de filtros
  DateTime? _filterDate;
  String? _filterType;
  String? _filterPlate;
  late List<Map<String, dynamic>> _filtered;
  Map<String, dynamic>? _featured;

  @override
  void initState() {
    super.initState();
    _filtered = allRecords;
    _featured = allRecords.first;
    // Establece el locale de intl si no lo tienes en tu main.dart
    // Int.defaultLocale = 'es';
  }

  void _applyFilters() {
    setState(() {
      _filtered = allRecords.where((r) {
        final matchDate = _filterDate == null ||
            DateFormat.yMd().format(r['date'] as DateTime) == DateFormat.yMd().format(_filterDate!);
        final matchType =
            _filterType == null || r['type']!.toString().toLowerCase().contains(_filterType!.toLowerCase());
        final matchPlate =
            _filterPlate == null || r['plate']!.toString().toLowerCase().contains(_filterPlate!.toLowerCase());
        return matchDate && matchType && matchPlate;
      }).toList();
      if (!_filtered.contains(_featured) && _filtered.isNotEmpty) {
        _featured = _filtered.first;
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
      setState(() => _filterDate = d);
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = _featured!;
    
    return Scaffold(
      body: Column(
        children: [
          // **PREVIEW CARD - AHORA COMO UN CONTAINER CON BORDES INFERIORES REDONDEADOS**
          Container(
            margin: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color:Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: IntrinsicHeight( // Para que el Row se ajuste a la altura del contenido más alto
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Para estirar los hijos verticalmente
                children: [
                  // Placeholder preview
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                    ),
                    child: Container(
                      width: 120,
                      color: Colors.grey.shade300,
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
                            f['place'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(f['description'], style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            'Fecha: ${DateFormat('dd MMM - HH:mm', 'es').format(f['date'])}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text('Matrícula: ${f['plate']}', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(
                            'Obs: ${f['observations']}',
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
          ),
          
          const SizedBox(height: 12),
          
          // FILTROS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Fecha con botón y clear
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
                // Tipo como input texto
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      _filterType = v.isEmpty ? null : v;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Matrícula como input texto
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
          
          const SizedBox(height: 12),
          
          // HISTORIAL - ListView sin slivers
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final rec = _filtered[i];
                final isToday = DateFormat('yyyyMMdd').format(rec['date']) ==
                    DateFormat('yyyyMMdd').format(DateTime.now());
                final dateFmt = DateFormat('dd', 'es').format(rec['date']);
                final monthFmt = DateFormat('MMM', 'es').format(rec['date']);
                final timeFmt = DateFormat('HH:mm').format(rec['date']);

                return InkWell(
                  onTap: () => setState(() => _featured = rec),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Fecha con diseño personalizado
                        Column(
                          children: [
                            Text(
                              dateFmt,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.red : Colors.black,
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
                        // Matrícula y tipo
                        Expanded(
                          child: Text(
                            rec['plate'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            rec['type'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (rec == _featured)
                          const Icon(Icons.check, color: Colors.blue),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}