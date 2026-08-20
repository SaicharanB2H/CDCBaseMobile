import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/unified_calendar_event.dart';
import '../theme/app_theme.dart';

class CalendarWidget extends StatefulWidget {
  final List<UnifiedCalendarEvent> unifiedEvents;
  final Function(DateTime selectedDay) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.unifiedEvents,
    required this.onDaySelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
  }

  List<UnifiedEventType> _getEventsForDay(DateTime day) {
    final String formattedDate =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    final List<UnifiedEventType> types = [];
    
    for (var ev in widget.unifiedEvents) {
      if (ev.dateStr == formattedDate) {
        if (!types.contains(ev.type)) types.add(ev.type);
      }
    }
    
    types.sort((a, b) => a.index.compareTo(b.index));
    return types;
  }

  Future<void> _syncGoogleCalendar() async {
    const url = 'https://calendar.google.com/calendar/r?cid=f55000cbb3ec133a52d7b7fcb06e14facf32b7609820269c7f590745c12e3423@group.calendar.google.com';
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Failed to launch calendar URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.calendar, size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'Placement Calendar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  final now = DateTime.now();
                  setState(() {
                    _focusedDay = now;
                    _selectedDay = now;
                  });
                  widget.onDaySelected(now);
                },
                icon: const Icon(LucideIcons.calendarClock, size: 16),
                label: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _syncGoogleCalendar,
                icon: const Icon(LucideIcons.calendarPlus, color: AppTheme.success),
                tooltip: 'Sync to Google Calendar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          TableCalendar<UnifiedEventType>(
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
              weekendTextStyle: TextStyle(color: AppTheme.textPrimary),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.surfaceLight,
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textPrimary),
              rightChevronIcon: const Icon(LucideIcons.chevronRight, color: AppTheme.textPrimary),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((event) {
                      Color dotColor = AppTheme.primary; // mailScheduled
                      if (event == UnifiedEventType.shortlist) dotColor = AppTheme.success;
                      if (event == UnifiedEventType.upcoming) dotColor = AppTheme.warning; // Purple

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(AppTheme.success, 'Shortlisted'),
              _buildLegendItem(AppTheme.primary, 'Mail Scheduled'),
              _buildLegendItem(AppTheme.warning, 'Upcoming'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
