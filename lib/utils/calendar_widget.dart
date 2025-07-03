// lib/widgets/calendar_widget.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Widget de calendario con marcadores de días y callback de selección.
class CalendarWidget extends StatefulWidget {
  /// Mapa de eventos: fecha → lista de objetos (puedes usar sólo la longitud).
  final Map<DateTime, List<dynamic>> events;

  /// Fecha seleccionada inicialmente (por defecto hoy).
  final DateTime? initialDate;

  /// Callback cuando el usuario selecciona un día.
  final void Function(DateTime day)? onDaySelected;

  const CalendarWidget({
    Key? key,
    this.events = const {},
    this.initialDate,
    this.onDaySelected,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate ?? _focusedDay;
    _selectedEvents = ValueNotifier(
      widget.events[_selectedDay] ?? [],
    );
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // Aseguramos que la clave coincida sin horas
    final d = DateTime(day.year, day.month, day.day);
    return widget.events[d] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar<dynamic>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      eventLoader: _getEventsForDay,
      calendarStyle: const CalendarStyle(
        // Pinta el día seleccionado
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _selectedEvents.value = _getEventsForDay(selectedDay);
        });
        if (widget.onDaySelected != null) {
          widget.onDaySelected!(selectedDay);
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }
}
