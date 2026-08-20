import 'event_model.dart';

enum UnifiedEventType { shortlist, mailScheduled, upcoming }

class UnifiedCalendarEvent {
  final String id;
  final String companyName;
  final String dateStr;
  final String subject;
  final UnifiedEventType type;
  final EventModel? rawEvent;
  final String? displayTime;
  final DateTime? parsedDate;

  UnifiedCalendarEvent({
    required this.id,
    required this.companyName,
    required this.dateStr,
    required this.subject,
    required this.type,
    this.rawEvent,
    this.displayTime,
    this.parsedDate,
  });
}
