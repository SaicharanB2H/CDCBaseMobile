class EventModel {
  final dynamic id;
  final String companyName;
  final String subject;
  final String eventDate;
  final String scheduledDateTime;
  final String body;
  final List<String> links;
  final List<String> shortlistedRegs;
  final String createdAt;
  final String receivedAt;

  EventModel({
    required this.id,
    required this.companyName,
    required this.subject,
    required this.eventDate,
    required this.scheduledDateTime,
    required this.body,
    required this.links,
    required this.shortlistedRegs,
    required this.createdAt,
    required this.receivedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedLinks = [];
    if (json['links'] != null) {
      if (json['links'] is List) {
        parsedLinks = List<String>.from(json['links']);
      } else if (json['links'] is String) {
        parsedLinks = [json['links']];
      }
    }

    List<String> parsedShortlists = [];
    if (json['shortlisted_regs'] != null) {
      if (json['shortlisted_regs'] is List) {
        parsedShortlists = List<String>.from(json['shortlisted_regs']);
      }
    }

    final scheduledStr = json['scheduled_date_time'] ?? json['scheduledDateTime'] ?? '';
    final receivedStr = json['received_at'] ?? json['receivedAt'] ?? '';
    final createdStr = json['created_at'] ?? json['createdAt'] ?? '';

    // Deriving eventDate from scheduled_date_time, received_at, or created_at
    String derivedEventDate = '';
    if (scheduledStr.isNotEmpty && scheduledStr.length >= 10) {
      derivedEventDate = scheduledStr.substring(0, 10);
    } else if (receivedStr.isNotEmpty && receivedStr.length >= 10) {
      derivedEventDate = receivedStr.substring(0, 10);
    } else if (createdStr.isNotEmpty && createdStr.length >= 10) {
      derivedEventDate = createdStr.substring(0, 10);
    } else {
      derivedEventDate = json['event_date'] ?? json['eventDate'] ?? '';
    }

    return EventModel(
      id: json['id'],
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      subject: json['subject'] ?? '',
      eventDate: derivedEventDate,
      scheduledDateTime: scheduledStr,
      body: json['body'] ?? '',
      links: parsedLinks,
      shortlistedRegs: parsedShortlists,
      createdAt: createdStr,
      receivedAt: receivedStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'subject': subject,
      'event_date': eventDate,
      'scheduled_date_time': scheduledDateTime,
      'body': body,
      'links': links,
      'shortlisted_regs': shortlistedRegs,
      'created_at': createdAt,
      'received_at': receivedAt,
    };
  }
}
