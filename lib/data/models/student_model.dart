class StudentModel {
  final String id;
  final String email;
  final String regNo;
  final String neopatId;
  final bool isAnonymous;

  StudentModel({
    required this.id,
    required this.email,
    required this.regNo,
    required this.neopatId,
    this.isAnonymous = false,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      regNo: json['reg_no'] ?? '',
      neopatId: json['neopat_id'] ?? '',
      isAnonymous: json['is_anonymous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'reg_no': regNo,
      'neopat_id': neopatId,
      'is_anonymous': isAnonymous,
    };
  }

  StudentModel copyWith({
    String? id,
    String? email,
    String? regNo,
    String? neopatId,
    bool? isAnonymous,
  }) {
    return StudentModel(
      id: id ?? this.id,
      email: email ?? this.email,
      regNo: regNo ?? this.regNo,
      neopatId: neopatId ?? this.neopatId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
