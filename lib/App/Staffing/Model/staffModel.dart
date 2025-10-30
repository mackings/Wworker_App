class StaffModel {
  final String id;
  final String fullname;
  final String email;
  final String phoneNumber;
  final String position;
  final String role;
  final bool accessGranted;
  final bool isVerified;
  final String createdAt;

  StaffModel({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phoneNumber,
    required this.position,
    required this.role,
    required this.accessGranted,
    required this.isVerified,
    required this.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      position: json['position'] ?? '',
      role: json['role'] ?? 'staff',
      accessGranted: json['accessGranted'] ?? true,
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullname': fullname,
      'email': email,
      'phoneNumber': phoneNumber,
      'position': position,
      'role': role,
      'accessGranted': accessGranted,
      'isVerified': isVerified,
      'createdAt': createdAt,
    };
  }
}