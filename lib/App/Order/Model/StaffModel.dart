class StaffModel {
  final String id;
  final String fullname;
  final String email;
  final String phoneNumber;
  final String position;
  final String role;

  StaffModel({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phoneNumber,
    required this.position,
    required this.role,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      position: json['position'] ?? '',
      role: json['role'] ?? '',
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
    };
  }

  // Helper to display name (use fullname if available, otherwise email)
  String get displayName => fullname.isNotEmpty ? fullname : email;
  
  // Helper to show role badge text
  String get roleText => role == 'admin' ? 'Admin' : 'Staff';
}