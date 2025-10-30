import 'package:flutter/material.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';
import 'package:wworker/App/Staffing/View/addStaff.dart';
import 'package:wworker/App/Staffing/View/manage.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class StaffAccessWidget extends StatelessWidget {
  final VoidCallback? onDeleteAccount;

  const StaffAccessWidget({super.key, this.onDeleteAccount});

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
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => SelectOptionSheet(
                          title: "Select Action",
                          options: [
                            OptionItem(
                              label: "Add Staff",
                              onTap: () {
                                Nav.push(AddStaff());
                              },
                            ),
                            OptionItem(
                              label: "Manage Staff",
                              onTap: () {
                                Nav.push(StaffManagement());
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => SelectOptionSheet(
                          title: "Staff Access",
                          options: [
                            OptionItem(label: "Add New Staff", onTap: () {}),
                            OptionItem(label: "View Staff List", onTap: () {}),
                            OptionItem(
                              label: "Manage Permissions",
                              onTap: () {},
                            ),
                          ],
                        ),
                      );
                    },
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
                    onTap: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                if (onDeleteAccount != null) {
                                  onDeleteAccount!();
                                }
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFFD72638)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
