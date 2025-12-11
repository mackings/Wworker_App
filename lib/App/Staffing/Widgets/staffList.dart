import 'package:flutter/material.dart';
import 'package:wworker/App/Staffing/Model/staffModel.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class StaffListItem extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onToggleAccess;
  final VoidCallback onDelete;

  const StaffListItem({
    super.key,
    required this.staff,
    required this.onToggleAccess,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Disable actions for owner
    final bool canModify = !staff.isOwner;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: ShapeDecoration(
        color: staff.accessGranted ? Colors.white : const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: staff.accessGranted 
                ? const Color(0xFFD3D3D3) 
                : const Color(0xFFE0E0E0),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Staff Name & Info - Takes more space
          Expanded(
            flex: 3,
            child: Opacity(
              opacity: staff.accessGranted ? 1.0 : 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          title: staff.fullname,
                          titleColor: const Color(0xFF302E2E),
                          titleFontSize: 13,
                          titleFontWeight: FontWeight.w600,
                        ),
                      ),
                      // Access Status Badge
                      if (!staff.accessGranted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD72638),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REVOKED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      // Owner badge
                      if (staff.isOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OWNER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      // Admin badge
                      if (staff.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB7835E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    title: staff.position,
                    titleColor: const Color(0xFF7B7B7B),
                    titleFontSize: 10,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    title: staff.email,
                    titleColor: const Color(0xFF7B7B7B),
                    titleFontSize: 9,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Grant/Revoke Access Button
          Flexible(
            flex: 2,
            child: GestureDetector(
              onTap: canModify ? onToggleAccess : null,
              child: Opacity(
                opacity: canModify ? 1.0 : 0.4,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: ShapeDecoration(
                    color: staff.accessGranted
                        ? const Color(0xFFD72638) // Red for revoke
                        : const Color(0xFF4CAF50), // Green for grant
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CustomText(
                        title: staff.accessGranted ? 'Revoke' : 'Grant',
                        titleColor: const Color(0xFFFEFEFE),
                        titleFontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Delete Button
          GestureDetector(
            onTap: canModify ? onDelete : null,
            child: Opacity(
              opacity: canModify ? 1.0 : 0.4,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1,
                      color: Color(0xFFD72638),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Color(0xFFD72638),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}