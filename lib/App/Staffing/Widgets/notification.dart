import 'package:flutter/material.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  bool pushNotificationEnabled = false;
  bool emailNotificationEnabled = false;
  bool quotationRemindersEnabled = false;
  bool projectDeadlinesEnabled = false;
  bool backupAlertsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFFD3D3D3)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 24,
                    color: Color(0xFF302E2E),
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    title: 'Notifications',
                    titleColor: const Color(0xFF302E2E),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Notification Options
              Column(
                children: [
                  // Push Notification
                  _buildNotificationOption(
                    title: 'Push Notification',
                    subtitle: 'Receive app notifications',
                    value: pushNotificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        pushNotificationEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Email Notification
                  _buildNotificationOption(
                    title: 'Email Notification',
                    subtitle: 'Important updates via email',
                    value: emailNotificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        emailNotificationEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quotation Reminders
                  _buildNotificationOption(
                    title: 'Quotation Reminders',
                    subtitle: 'Follow-up on pending quote',
                    value: quotationRemindersEnabled,
                    onChanged: (value) {
                      setState(() {
                        quotationRemindersEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Project Deadlines
                  _buildNotificationOption(
                    title: 'Project Deadlines',
                    subtitle: 'Deadline approaching alerts',
                    value: projectDeadlinesEnabled,
                    onChanged: (value) {
                      setState(() {
                        projectDeadlinesEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Backup Alerts
                  _buildNotificationOption(
                    title: 'Backup Alerts',
                    subtitle: 'Backup status notifications',
                    value: backupAlertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        backupAlertsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title: title,
                  titleColor: const Color(0xFF302E2E),
                  titleFontSize: 15,
                ),
                const SizedBox(height: 4),
                CustomText(
                  subtitle: subtitle,
                  titleColor: const Color(0xFF7B7B7B),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF9CBA7F),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
