import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Staffing/Api/staffService.dart';
import 'package:wworker/App/Staffing/Model/staffModel.dart';
import 'package:wworker/App/Staffing/View/addStaff.dart';
import 'package:wworker/App/Staffing/Widgets/staffList.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class StaffManagement extends ConsumerStatefulWidget {
  const StaffManagement({super.key});

  @override
  ConsumerState<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends ConsumerState<StaffManagement> {
  final StaffService _staffService = StaffService();
  List<StaffModel> staffList = [];
  List<StaffModel> filteredStaffList = [];
  bool isLoading = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() => isLoading = true);

    try {
      final result = await _staffService.getAllStaff();

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
          ? await _staffService.revokeAccess(staff.id)
          : await _staffService.grantAccess(staff.id);

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
        _loadStaff(); // Reload list
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
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text(
          'Are you sure you want to delete ${staff.fullname}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFD72638)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _staffService.deleteStaff(staff.id);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Staff deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStaff(); // Reload list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to delete staff'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Nav.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddStaff()),
              );
              _loadStaff(); // Reload after adding staff
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  CustomText(
                    title: 'Staff List',
                    titleFontSize: 16,
                    titleFontWeight: FontWeight.w600,
                    titleColor: const Color(0xFF302E2E),
                  ),
                ],
              ),
            ),

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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStaffList.isEmpty
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
                            // Table Header
                            _buildTableHeader(),
                            const SizedBox(height: 16),

                            // Staff List Items
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
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CustomText(
                title: 'Staff Name',
                titleColor: const Color(0xFF8B4513),
                titleFontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomText(
                  title: 'Access',
                  titleColor: const Color(0xFF8B4513),
                  titleFontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomText(
                  title: 'Delete',
                  titleColor: const Color(0xFF8B4513),
                  titleFontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
