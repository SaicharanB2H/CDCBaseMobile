class StudentModel {
  final String id;
  final String email;
  final String regNo;
  final String neopatId;
  final double class10Perc;
  final double class12Perc;
  final double ugCgpa;
  final int arrears;
  final String degree;

  StudentModel({
    required this.id,
    required this.email,
    required this.regNo,
    required this.neopatId,
    required this.class10Perc,
    required this.class12Perc,
    required this.ugCgpa,
    required this.arrears,
    required this.degree,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      regNo: json['reg_no'] ?? '',
      neopatId: json['neopat_id'] ?? '',
      class10Perc: (json['class_10_perc'] as num?)?.toDouble() ?? 0.0,
      class12Perc: (json['class_12_perc'] as num?)?.toDouble() ?? 0.0,
      ugCgpa: (json['ug_cgpa'] as num?)?.toDouble() ?? 0.0,
      arrears: (json['arrears'] as num?)?.toInt() ?? (json['history_of_arrears'] as num?)?.toInt() ?? 0,
      degree: json['degree'] ?? 'B.Tech',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'reg_no': regNo,
      'neopat_id': neopatId,
      'class_10_perc': class10Perc,
      'class_12_perc': class12Perc,
      'ug_cgpa': ugCgpa,
      'arrears': arrears,
      'degree': degree,
    };
  }

  StudentModel copyWith({
    String? id,
    String? email,
    String? regNo,
    String? neopatId,
    double? class10Perc,
    double? class12Perc,
    double? ugCgpa,
    int? arrears,
    String? degree,
  }) {
    return StudentModel(
      id: id ?? this.id,
      email: email ?? this.email,
      regNo: regNo ?? this.regNo,
      neopatId: neopatId ?? this.neopatId,
      class10Perc: class10Perc ?? this.class10Perc,
      class12Perc: class12Perc ?? this.class12Perc,
      ugCgpa: ugCgpa ?? this.ugCgpa,
      arrears: arrears ?? this.arrears,
      degree: degree ?? this.degree,
    );
  }
}
