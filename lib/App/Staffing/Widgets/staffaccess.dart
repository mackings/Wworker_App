import 'package:flutter/material.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';



class StaffAccessWidget extends StatelessWidget {
  final VoidCallback? onManageAccount;
  final VoidCallback? onStaffAccess;
  final VoidCallback? onDeleteAccount;

  const StaffAccessWidget({
    super.key,
    this.onManageAccount,
    this.onStaffAccess,
    this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0xFFD3D3D3),
              ),
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
                    Icons.security_outlined,
                    size: 24,
                    color: Color(0xFF302E2E),
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    title: 'Privacy & Security',
                    titleColor: const Color(0xFF302E2E),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Options
              Column(
                children: [
                  // Manage Account Button
                  InkWell(
                    onTap: onManageAccount,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFF9CBA7F),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                            size: 24,
                            color: Color(0xFF9CBA7F),
                          ),
                          const SizedBox(width: 8),
                          CustomText(
                            title: 'Manage Account',
                            titleColor: const Color(0xFF9CBA7F),
                            titleFontSize: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Staff Access Button
                  InkWell(
                    onTap: onStaffAccess,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFF9CBA7F),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 24,
                            color: Color(0xFF9CBA7F),
                          ),
                          const SizedBox(width: 8),
                          CustomText(
                            title: 'Staff Access',
                            titleColor: const Color(0xFF9CBA7F),
                             titleFontSize: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Delete Account Button
                  InkWell(
                    onTap: onDeleteAccount,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFFD72638),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 24,
                            color: Color(0xFFD72638),
                          ),
                          const SizedBox(width: 8),
                          CustomText(
                            title: 'Delete Account',
                            titleColor: const Color(0xFFD72638),
                             titleFontSize: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}