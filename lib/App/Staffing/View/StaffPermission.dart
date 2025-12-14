

import 'package:flutter/material.dart';
import 'package:wworker/App/Staffing/Api/permissionService.dart';
import 'package:wworker/App/Staffing/Model/staffModel.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';


class StaffPermissionsModal extends StatefulWidget {
  final StaffModel staff;

  const StaffPermissionsModal({
    super.key,
    required this.staff,
  });

  @override
  State<StaffPermissionsModal> createState() => _StaffPermissionsModalState();
}

class _StaffPermissionsModalState extends State<StaffPermissionsModal> {
  final PermissionService _permissionService = PermissionService();
  bool isLoading = true;
  bool isSaving = false;

  List<Map<String, dynamic>> permissions = [
    {
      'id': 'quotation',
      'title': 'Quotation',
      'description': 'Give access for quotation',
      'value': false,
    },
    // {
    //   'id': 'sales',
    //   'title': 'Sales',
    //   'description': 'Give access for sales',
    //   'value': false,
    // },
    {
      'id': 'order',
      'title': 'Order',
      'description': 'Give access for order',
      'value': false,
    },
    {
      'id': 'database',
      'title': 'Database',
      'description': 'Give access for database',
      'value': false,
    },
    // {
    //   'id': 'receipts',
    //   'title': 'Receipts',
    //   'description': 'View and manage receipts',
    //   'value': false,
    // },
    // {
    //   'id': 'backupAlerts',
    //   'title': 'Backup Alerts',
    //   'description': 'Backup status notifications',
    //   'value': false,
    // },
    {
      'id': 'invoice',
      'title': 'Invoice',
      'description': 'Create and manage invoices',
      'value': false,
    },
    {
      'id': 'products',
      'title': 'Products',
      'description': 'Manage products and inventory',
      'value': false,
    },
    // {
    //   'id': 'boms',
    //   'title': 'BOMs',
    //   'description': 'Manage Bills of Materials',
    //   'value': false,
    // },
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => isLoading = true);

    try {
      final response = await _permissionService.getStaffPermissions(
        staffId: widget.staff.id,
      );

      if (response['success'] == true) {
        final staffPermissions = response['data']['permissions'] as Map<String, dynamic>?;
        
        if (staffPermissions != null) {
          setState(() {
            for (var i = 0; i < permissions.length; i++) {
              final permId = permissions[i]['id'];
              permissions[i]['value'] = staffPermissions[permId] ?? false;
            }
          });
        }
      } else {
        _showError(response['message'] ?? 'Failed to load permissions');
      }
    } catch (e) {
      _showError('Error loading permissions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _savePermissions() async {
    setState(() => isSaving = true);

    try {
      // Build permissions map
      final permissionsMap = <String, bool>{};
      for (var permission in permissions) {
        permissionsMap[permission['id']] = permission['value'];
      }

      final response = await _permissionService.updateStaffPermissions(
        staffId: widget.staff.id,
        permissions: permissionsMap,
      );

      if (response['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Permissions updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => isSaving = false);
        _showError(response['message'] ?? 'Failed to update permissions');
      }
    } catch (e) {
      setState(() => isSaving = false);
      _showError('Error updating permissions: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                const Text(
                  'Manage Permissions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF302E2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set permissions for ${widget.staff.fullname}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Loading or Permissions List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B4513),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: permissions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final permission = permissions[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            permissions[index]['value'] = !permissions[index]['value'];
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      permission['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF302E2E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      permission['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Switch(
                                value: permission['value'],
                                onChanged: (value) {
                                  setState(() {
                                    permissions[index]['value'] = value;
                                  });
                                },
                                activeColor: const Color(0xFF8B4513),
                                activeTrackColor: const Color(0xFF8B4513).withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Continue Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isLoading || isSaving) ? null : _savePermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}