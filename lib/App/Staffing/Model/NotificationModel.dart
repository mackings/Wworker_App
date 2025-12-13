class NotificationModel {
  final String id;
  final String userId;
  final String companyName;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? performedBy;
  final String? performedByName;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.performedBy,
    this.performedByName,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      companyName: json['companyName'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      performedBy: json['performedBy']?['_id'],
      performedByName: json['performedBy']?['fullname'] ?? json['performedByName'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'companyName': companyName,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}