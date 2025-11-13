import 'package:flutter/material.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class DatabaseWidget extends StatefulWidget {
  const DatabaseWidget({super.key});

  @override
  State<DatabaseWidget> createState() => _DatabaseWidgetState();
}

class _DatabaseWidgetState extends State<DatabaseWidget> {
  bool cloudSyncEnabled = false;
  bool autoBackupEnabled = false;

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
              // Database Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFF9CBA7F)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.storage,
                      size: 24,
                      color: Color(0xFF9CBA7F),
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      title: 'Database',
                      titleColor: const Color(0xFF9CBA7F),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Cloud Sync Option
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
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
                            title: 'Cloud Sync',
                            titleFontSize: 15,
                            titleColor: const Color(0xFF302E2E),
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            subtitle: 'Sync data across all devices',
                            titleColor: const Color(0xFF7B7B7B),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: cloudSyncEnabled,
                        onChanged: (value) {
                          setState(() {
                            cloudSyncEnabled = value;
                          });
                        },
                        activeColor: const Color(0xFF9CBA7F),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Auto Backup Option
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
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
                            title: 'Auto Backup',
                            titleFontSize: 15,
                            titleColor: const Color(0xFF302E2E),
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            subtitle: 'Daily automatic backups',
                            titleColor: const Color(0xFF7B7B7B),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: autoBackupEnabled,
                        onChanged: (value) {
                          setState(() {
                            autoBackupEnabled = value;
                          });
                        },
                        activeColor: const Color(0xFF9CBA7F),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
