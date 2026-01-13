import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Staffing/Api/staffService.dart';
import 'package:wworker/App/Staffing/Model/staffModel.dart';
import 'package:wworker/App/Staffing/View/StaffPermission.dart';
import 'package:wworker/App/Staffing/View/addCompany.dart';
import 'package:wworker/App/Staffing/View/addStaff.dart';
import 'package:wworker/App/Staffing/Widgets/staffList.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';




class StaffManagement extends ConsumerStatefulWidget {
  const StaffManagement({super.key});

  @override
  ConsumerState<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends ConsumerState<StaffManagement> {
  final CompanyService _companyService = CompanyService();
  List<StaffModel> staffList = [];
  List<StaffModel> filteredStaffList = [];
  bool isLoading = true;
  bool hasCompany = false;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCompanyAndLoadStaff();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _checkCompanyAndLoadStaff() async {
    setState(() => isLoading = true);

    // Check if user has a company
    final prefs = await SharedPreferences.getInstance();
    final companiesString = prefs.getString("companies");
    
    if (companiesString == null || companiesString.isEmpty) {
      setState(() {
        hasCompany = false;
        isLoading = false;
      });
      return;
    }

    final companies = jsonDecode(companiesString) as List;
    if (companies.isEmpty) {
      setState(() {
        hasCompany = false;
        isLoading = false;
      });
      return;
    }

    setState(() => hasCompany = true);
    await _loadStaff();
  }

  Future<void> _loadStaff() async {
    if (!hasCompany) return;

    setState(() => isLoading = true);

    try {
      final result = await _companyService.getCompanyStaff();

      if (result['success'] == true) {
        final data = result['data'] as List;
        setState(() {
          staffList = data.map((json) => StaffModel.fromJson(json)).toList();
          filteredStaffList = staffList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to load staff'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _searchStaff(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredStaffList = staffList;
      } else {
        filteredStaffList = staffList
            .where(
              (staff) =>
                  staff.fullname.toLowerCase().contains(query.toLowerCase()) ||
                  staff.email.toLowerCase().contains(query.toLowerCase()) ||
                  staff.position.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _toggleAccess(StaffModel staff) async {
    try {
      final result = staff.accessGranted
          ? await _companyService.revokeStaffAccess(userId: staff.id)
          : await _companyService.restoreStaffAccess(userId: staff.id);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              staff.accessGranted
                  ? '✅ Access revoked successfully'
                  : '✅ Access granted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadStaff();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update access'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    if (staff.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove company owner'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text(
          'Are you sure you want to remove ${staff.fullname}? This will permanently remove them from the company.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFD72638)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _companyService.removeStaff(userId: staff.id);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Staff removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStaff();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to remove staff'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: CustomText(
          title: 'Staff List',
          titleFontSize: 16,
          titleFontWeight: FontWeight.w600,
          titleColor: const Color(0xFF302E2E),
        ),
        actions: hasCompany
            ? [
                const GuideHelpIcon(
                  title: "Staff Management",
                  message:
                      "Step 1: review your staff list. Step 2: add new staff or "
                      "open a profile to adjust permissions. Step 3: keep roles "
                      "aligned with responsibilities. The goal is secure access "
                      "and clear accountability.",
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.black),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddStaff()),
                    );
                    _loadStaff();
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasCompany
                ? _buildNoCompanyView()
                : _buildStaffListView(),
      ),
    );
  }

  // 🟢 No Company View
  Widget _buildNoCompanyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_outlined,
                size: 80,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 30),
            CustomText(
              title: 'No Company Yet',
              titleFontSize: 24,
              titleFontWeight: FontWeight.bold,
              titleColor: const Color(0xFF302E2E),
            ),
            const SizedBox(height: 12),
            CustomText(
              title: 'Create a company to start adding staff members',
              titleColor: Colors.grey.shade600,
              titleFontSize: 14,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateCompanyScreen(),
                    ),
                  );
                  _checkCompanyAndLoadStaff();
                },
                icon: const Icon(Icons.add_business, color: Colors.white),
                label: const Text(
                  'Create Company',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Navigate to learn more or skip
              },
              child: Text(
                'Learn More',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 Staff List View
  Widget _buildStaffListView() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: const Color(0xFFF9F9F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF7B7B7B)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: _searchStaff,
                    style: const TextStyle(
                      color: Color(0xFF302E2E),
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: Color(0xFF7B7B7B),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Staff List
        Expanded(
          child: filteredStaffList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      CustomText(
                        title: searchController.text.isEmpty
                            ? 'No staff members yet'
                            : 'No results found',
                        titleColor: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      if (searchController.text.isEmpty)
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddStaff(),
                              ),
                            );
                            _loadStaff();
                          },
                          child: const Text('Add First Staff Member'),
                        ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFCFCFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTableHeader(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredStaffList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final staff = filteredStaffList[index];
                              return StaffListItem(
                                staff: staff,
                                onToggleAccess: () => _toggleAccess(staff),
                                onDelete: () => _deleteStaff(staff),
                                onManagePermissions: staff.isOwner 
                                    ? null 
                                    : () async {
                                        // ✅ Show permissions modal
                                        final result = await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => StaffPermissionsModal(staff: staff),
                                        );

                                        // Reload staff if permissions were updated
                                        if (result == true) {
                                          _loadStaff();
                                        }
                                      },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ✅ Updated Table Header
  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F8F2),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF8B4513)),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              title: 'Staff Members',
              titleColor: const Color(0xFF8B4513),
              titleFontSize: 13,
              titleFontWeight: FontWeight.w600,
            ),
          ),
          CustomText(
            title: '${filteredStaffList.length} ${filteredStaffList.length == 1 ? 'person' : 'people'}',
            titleColor: const Color(0xFF8B4513),
            titleFontSize: 12,
          ),
        ],
      ),
    );
  }
}
