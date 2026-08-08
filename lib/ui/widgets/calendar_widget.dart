import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/event_model.dart';
import '../../data/models/company_model.dart';
import '../theme/app_theme.dart';

class CalendarWidget extends StatefulWidget {
  final List<EventModel> events;
  final List<CompanyModel> companies;
  final Function(DateTime selectedDay) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.events,
    required this.companies,
    required this.onDaySelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime(2026, 8, 1);
  DateTime? _selectedDay;

  List<String> _getEventsForDay(DateTime day) {
    final String formattedDate =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    final List<String> list = [];
    for (var ev in widget.events) {
      if (ev.eventDate == formattedDate) {
        list.add(ev.companyName);
      }
    }
    for (var comp in widget.companies) {
      if (comp.visitDate == formattedDate && !list.contains(comp.companyName)) {
        list.add(comp.companyName);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(8.0),
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDaySelected(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: (day) {
          return _getEventsForDay(day);
        },
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: AppTheme.textPrimary),
          weekendTextStyle: TextStyle(color: AppTheme.accent),
          selectedDecoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppTheme.success,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
          ),
          titleTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textPrimary),
          rightChevronIcon: const Icon(LucideIcons.chevronRight, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
