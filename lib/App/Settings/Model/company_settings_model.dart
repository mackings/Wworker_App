class CompanySettings {
  final String id;
  final String companyName;
  final bool cloudSyncEnabled;
  final bool autoBackupEnabled;
  final NotificationSettings notifications;

  CompanySettings({
    required this.id,
    required this.companyName,
    required this.cloudSyncEnabled,
    required this.autoBackupEnabled,
    required this.notifications,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      id: json['_id'] ?? '',
      companyName: json['companyName'] ?? '',
      cloudSyncEnabled: json['cloudSyncEnabled'] ?? false,
      autoBackupEnabled: json['autoBackupEnabled'] ?? false,
      notifications: NotificationSettings.fromJson(
        json['notifications'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'companyName': companyName,
      'cloudSyncEnabled': cloudSyncEnabled,
      'autoBackupEnabled': autoBackupEnabled,
      'notifications': notifications.toJson(),
    };
  }
}

class NotificationSettings {
  final bool pushNotification;
  final bool emailNotification;
  final bool quotationReminders;
  final bool projectDeadlines;
  final bool backupAlerts;

  NotificationSettings({
    required this.pushNotification,
    required this.emailNotification,
    required this.quotationReminders,
    required this.projectDeadlines,
    required this.backupAlerts,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotification: json['pushNotification'] ?? false,
      emailNotification: json['emailNotification'] ?? false,
      quotationReminders: json['quotationReminders'] ?? false,
      projectDeadlines: json['projectDeadlines'] ?? false,
      backupAlerts: json['backupAlerts'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotification': pushNotification,
      'emailNotification': emailNotification,
      'quotationReminders': quotationReminders,
      'projectDeadlines': projectDeadlines,
      'backupAlerts': backupAlerts,
    };
  }
}
