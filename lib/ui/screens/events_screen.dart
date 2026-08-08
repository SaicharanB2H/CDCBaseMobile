import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/company_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_model.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_widget.dart';

class EventsScreen extends StatefulWidget {
  final StudentModel? student;
  final List<EventModel> events;
  final List<CompanyModel> companies;

  const EventsScreen({
    super.key,
    required this.student,
    required this.events,
    required this.companies,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime? _selectedCalendarDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'Placement Events & Calendar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: _buildCalendarTab(),
    );
  }

  Widget _buildCalendarTab() {
    List<EventModel> dayEvents = [];
    if (_selectedCalendarDate != null) {
      final dateStr =
          "${_selectedCalendarDate!.year}-${_selectedCalendarDate!.month.toString().padLeft(2, '0')}-${_selectedCalendarDate!.day.toString().padLeft(2, '0')}";
      dayEvents = widget.events.where((e) => e.eventDate == dateStr).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalendarWidget(
            events: widget.events,
            companies: widget.companies,
            onDaySelected: (day) {
              setState(() {
                _selectedCalendarDate = day;
              });
            },
          ),
          const SizedBox(height: 20),
          if (_selectedCalendarDate != null) ...[
            Text(
              'Events on ${_selectedCalendarDate!.day}/${_selectedCalendarDate!.month}/${_selectedCalendarDate!.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (dayEvents.isEmpty)
              const Text(
                'No scheduled events on this date.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final ev = dayEvents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        LucideIcons.calendar,
                        color: AppTheme.primary,
                      ),
                      title: Text(
                        ev.subject,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        ev.companyName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
