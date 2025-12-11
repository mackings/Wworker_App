class StaffModel {
  final String id;
  final String fullname;
  final String email;
  final String phoneNumber;
  final String role; // 'owner', 'admin', 'staff'
  final String position;
  final bool accessGranted; // ← Added back
  final String? joinedAt;

  StaffModel({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.position,
    required this.accessGranted, // ← Added back
    this.joinedAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'staff',
      position: json['position'] ?? '',
      accessGranted: json['accessGranted'] ?? true, // ← Added back
      joinedAt: json['joinedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'position': position,
      'accessGranted': accessGranted, // ← Added back
      'joinedAt': joinedAt,
    };
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canManageStaff => isOwner || isAdmin;
}