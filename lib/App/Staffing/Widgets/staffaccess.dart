import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';
import 'package:wworker/App/Staffing/View/addStaff.dart';
import 'package:wworker/App/Staffing/View/manage.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class StaffAccessWidget extends StatelessWidget {
  final VoidCallback? onDeleteAccount;

  const StaffAccessWidget({super.key, this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          const Text(
            "Manage staff access, roles, and account security",
            style: TextStyle(fontSize: 12, color: Color(0xFF7B7B7B)),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.account_circle_outlined,
            title: "Manage Account",
            subtitle: "Add staff or manage staff list",
            accentColor: const Color(0xFF9CBA7F),
            onTap: () => _showManageAccountSheet(context),
          ),
          const SizedBox(height: 10),
          // _buildActionTile(
          //   icon: Icons.people_outline,
          //   title: "Staff Access",
          //   subtitle: "Permissions and access rules",
          //   accentColor: const Color(0xFF9CBA7F),
          //   onTap: () => _showStaffAccessSheet(context),
          // ),
          const SizedBox(height: 14),
          _buildDangerTile(
            icon: Icons.delete_outline,
            title: "Delete Account",
            onTap: () => _showDeleteConfirm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF9CBA7F).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.security_outlined,
            size: 20,
            color: Color(0xFF9CBA7F),
          ),
        ),
        const SizedBox(width: 10),
        CustomText(
          title: 'Privacy & Security',
          titleColor: const Color(0xFF302E2E),
        ),
        const Spacer(),
        Consumer(
          builder: (context, ref, _) => const GuideHelpIcon(
            title: "Staff Management",
            message:
                "Use this section to add staff or manage roles and access. "
                "Step 1: add staff members. Step 2: review or edit access. "
                "The goal is to control who can view or edit company data.",
          ),
        ),
      ],
    );
  }

  void _showManageAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SelectOptionSheet(
        title: "Select Action",
        options: [
          OptionItem(
            label: "Add Staff",
            onTap: () => Nav.push(AddStaff()),
          ),
          OptionItem(
            label: "Manage Staff",
            onTap: () => Nav.push(StaffManagement()),
          ),
        ],
      ),
    );
  }

  void _showStaffAccessSheet(BuildContext context) {
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
  }

  void _showDeleteConfirm(BuildContext context) {
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
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.35)),
          color: accentColor.withOpacity(0.08),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6E6E6E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6E6E6E)),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD72638)),
          color: const Color(0xFFFFF2F2),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFFD72638)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD72638),
                ),
              ),
            ),
            const Icon(Icons.warning_amber, color: Color(0xFFD72638)),
          ],
        ),
      ),
    );
  }
}
