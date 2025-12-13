import 'package:flutter/material.dart';
import 'package:wworker/App/Staffing/Model/staffModel.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';



class StaffListItem extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onToggleAccess;
  final VoidCallback onDelete;
  final VoidCallback? onManagePermissions;

  const StaffListItem({
    super.key,
    required this.staff,
    required this.onToggleAccess,
    required this.onDelete,
    this.onManagePermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Staff Info Row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
                child: Text(
                  staff.fullname.isNotEmpty 
                      ? staff.fullname[0].toUpperCase() 
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF8B4513),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name and Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: CustomText(
                            title: staff.fullname,
                            titleFontSize: 14,
                            titleFontWeight: FontWeight.w600,
                            titleColor: const Color(0xFF302E2E),
                          ),
                        ),
                        if (staff.isOwner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4513).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Owner',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8B4513),
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
                      titleFontSize: 12,
                      titleColor: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action Buttons Row (only for non-owners)
          if (!staff.isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Permissions Button
                if (onManagePermissions != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onManagePermissions,
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Permissions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B4513),
                        side: const BorderSide(
                          color: Color(0xFF8B4513),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(width: 8),

                // Grant/Revoke Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onToggleAccess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: staff.accessGranted 
                          ? Colors.orange.shade600 
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      staff.accessGranted ? 'Revoke' : 'Grant',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Delete Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    onPressed: onDelete,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],

          // Owner placeholder
          if (staff.isOwner) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                'Company Owner',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}