class CompanyModel {
  final String companyName;
  final String ctc;
  final String stipend;
  final String visitDate;
  final String branches;
  final String eligibility;
  final String deadline;
  final String links;
  final String location;
  final List<dynamic> eventTimeline;
  final bool selected;
  final List<String> selectedReg;
  final String receivedAt;

  CompanyModel({
    required this.companyName,
    required this.ctc,
    required this.stipend,
    required this.visitDate,
    required this.branches,
    required this.eligibility,
    required this.deadline,
    required this.links,
    required this.location,
    required this.eventTimeline,
    required this.selected,
    required this.selectedReg,
    required this.receivedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSelectedReg = [];
    if (json['selected_reg'] != null) {
      if (json['selected_reg'] is List) {
        parsedSelectedReg = List<String>.from(json['selected_reg']);
      }
    }

    final rawTimeline = json['event_timeline'] ?? json['eventTimeline'];
    List<dynamic> parsedTimeline = [];
    if (rawTimeline is List) {
      parsedTimeline = rawTimeline;
    }

    return CompanyModel(
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      ctc: json['ctc'] ?? 'N/A',
      stipend: json['stipend'] ?? 'N/A',
      visitDate: json['visit_date'] ?? json['visitDate'] ?? '',
      branches: json['branches'] ?? 'All Branches',
      eligibility: json['eligibility'] ?? 'Refer Placement Cell',
      deadline: json['deadline'] ?? '',
      links: json['links'] ?? '',
      location: json['location'] ?? 'Pan-India',
      eventTimeline: parsedTimeline,
      selected: json['selected'] ?? false,
      selectedReg: parsedSelectedReg,
      receivedAt: json['received_at'] ?? json['receivedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'ctc': ctc,
      'stipend': stipend,
      'visit_date': visitDate,
      'branches': branches,
      'eligibility': eligibility,
      'deadline': deadline,
      'links': links,
      'location': location,
      'event_timeline': eventTimeline,
      'selected': selected,
      'selected_reg': selectedReg,
      'received_at': receivedAt,
    };
  }
}
