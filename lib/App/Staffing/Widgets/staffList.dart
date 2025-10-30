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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFD3D3D3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Staff Name - Takes more space
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  title: staff.fullname,
                  titleColor: const Color(0xFF302E2E),
                  titleFontSize: 13,
                  titleFontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 4),
                CustomText(
                  title: staff.position,
                  titleColor: const Color(0xFF7B7B7B),
                  titleFontSize: 10,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Access Toggle Button
          Flexible(
            flex: 2,
            child: GestureDetector(
              onTap: onToggleAccess,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: ShapeDecoration(
                  color: staff.accessGranted
                      ? const Color(0xFFD72638) // Red for revoke
                      : const Color(0xFFB7835E), // Brown for grant
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

          const SizedBox(width: 8),

          // Delete Button
          GestureDetector(
            onTap: onDelete,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD72638),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
