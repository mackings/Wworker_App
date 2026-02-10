import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Staffing/Api/staffService.dart';
import 'package:wworker/App/Staffing/Model/staffModel.dart';
import 'package:wworker/App/Staffing/View/StaffPermission.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class AddStaff extends ConsumerStatefulWidget {
  const AddStaff({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddStaffState();
}

class _AddStaffState extends ConsumerState<AddStaff> {
  final fullnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final positionController =
      TextEditingController(); // ✅ Changed to TextEditingController

  final CompanyService _companyService = CompanyService();

  bool isLoading = false;
  String? selectedRole;

  // ✅ List of roles
  final List<String> roles = ["admin", "staff"];

  StaffModel? _extractStaffFromInviteResult(Map<String, dynamic> result) {
    final data = result['data'];
    Map<String, dynamic>? staffJson;

    if (data is Map<String, dynamic>) {
      if (data['staff'] is Map) {
        staffJson = Map<String, dynamic>.from(data['staff'] as Map);
      } else if (data['user'] is Map) {
        staffJson = Map<String, dynamic>.from(data['user'] as Map);
      } else if (data['invitedStaff'] is Map) {
        staffJson = Map<String, dynamic>.from(data['invitedStaff'] as Map);
      } else if (data['data'] is Map) {
        // Some APIs nest again under `data`.
        staffJson = Map<String, dynamic>.from(data['data'] as Map);
      } else if (data['id'] != null) {
        staffJson = data;
      }
    } else if (data is Map) {
      staffJson = Map<String, dynamic>.from(data);
    }

    // If backend did not return staff payload, fall back to form values.
    // We still need an id to load permissions; this fallback only helps
    // with display once we resolve the id by fetching staff list.
    if (staffJson == null) return null;

    // Normalize some common backend keys.
    if (staffJson['id'] == null && staffJson['_id'] != null) {
      staffJson['id'] = staffJson['_id'];
    }

    return StaffModel.fromJson(staffJson);
  }

  Future<StaffModel?> _resolveInvitedStaffForPermissions({
    required Map<String, dynamic> inviteResult,
    required String email,
    required String fullname,
    required String phoneNumber,
    required String role,
    required String position,
  }) async {
    final extracted = _extractStaffFromInviteResult(inviteResult);
    if (extracted != null && extracted.id.isNotEmpty) {
      return extracted;
    }

    // If the invite response didn't include staff id, fetch staff list and match by email.
    final staffListResult = await _companyService.getCompanyStaff();
    if (staffListResult['success'] == true && staffListResult['data'] is List) {
      final list = (staffListResult['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final match = list.cast<Map<String, dynamic>?>().firstWhere(
        (m) =>
            (m?['email']?.toString().toLowerCase().trim() ?? '') ==
            email.toLowerCase().trim(),
        orElse: () => null,
      );

      if (match != null) {
        return StaffModel.fromJson(match);
      }
    }

    // Last resort: construct a local model (permissions fetch will fail without id).
    return StaffModel(
      id: extracted?.id ?? '',
      fullname: extracted?.fullname.isNotEmpty == true
          ? extracted!.fullname
          : fullname,
      email: extracted?.email.isNotEmpty == true ? extracted!.email : email,
      phoneNumber: extracted?.phoneNumber.isNotEmpty == true
          ? extracted!.phoneNumber
          : phoneNumber,
      role: extracted?.role.isNotEmpty == true ? extracted!.role : role,
      position: extracted?.position.isNotEmpty == true
          ? extracted!.position
          : position,
      accessGranted: extracted?.accessGranted ?? true,
      joinedAt: extracted?.joinedAt,
    );
  }

  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    positionController.dispose(); // ✅ Dispose position controller
    super.dispose();
  }

  Future<void> _inviteStaff() async {
    // Validate fields
    if (fullnameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedRole == null ||
        positionController.text.isEmpty) {
      // ✅ Changed validation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate phone number (basic validation)
    if (phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid phone number"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final fullname = fullnameController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final role = selectedRole!;
      final position = positionController.text.trim();

      final result = await _companyService.inviteStaff(
        fullname: fullname,
        email: email,
        phoneNumber: phone,
        role: role,
        position: position, // ✅ Using text input
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        if (mounted) {
          final invitedStaff = await _resolveInvitedStaffForPermissions(
            inviteResult: result,
            email: email,
            fullname: fullname,
            phoneNumber: phone,
            role: role,
            position: position,
          );

          // Show temp password if returned (optional)
          final tempPassword = result['data']?['tempPassword'];

          messenger.showSnackBar(
            SnackBar(
              content: Text(
                tempPassword != null
                    ? "✅ Staff invited! Temp password: $tempPassword"
                    : "✅ Staff invited successfully! Email sent.",
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Clear fields
          fullnameController.clear();
          emailController.clear();
          phoneController.clear();
          positionController.clear(); // ✅ Clear position field
          setState(() {
            selectedRole = null;
          });

          // Go directly to permissions for the newly invited staff.
          if (invitedStaff == null || invitedStaff.id.isEmpty) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  "Staff created, but couldn't open permissions (missing staff id).",
                ),
                backgroundColor: Colors.orange,
              ),
            );
            Nav.pop();
            return;
          }

          if (!mounted) return;
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => StaffPermissionsModal(staff: invitedStaff),
          );

          // After permissions, go back to staff list.
          navigator.pop();
        }
      } else {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                "❌ ${result['message'] ?? 'Failed to invite staff'}",
              ),
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
            content: Text("⚠️ Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: CustomText(title: "Add Staff")),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      subtitle:
                          "Create a new staff account. They'll receive login credentials via email.",
                      subtitleColor: Colors.grey,
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    CustomTextField(
                      label: "Full Name",
                      hintText: "Enter full name",
                      controller: fullnameController,
                    ),
                    const SizedBox(height: 20),

                    // Email
                    CustomTextField(
                      label: "Email",
                      hintText: "Enter email address",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    CustomTextField(
                      label: "Phone Number",
                      hintText: "Enter phone number",
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // ✅ Role Dropdown
                    CustomTextField(
                      label: "Role",
                      hintText: "Select role",
                      isDropdown: true,
                      dropdownItems: roles,
                      value: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // ✅ Position TextField (manual input)
                    CustomTextField(
                      label: "Position",
                      hintText:
                          "Enter position (e.g., Cabinet Maker, Sales Manager)",
                      controller: positionController,
                    ),
                    const SizedBox(height: 40),

                    CustomButton(
                      text: "Add Staff",
                      loading: isLoading,
                      onPressed: _inviteStaff,
                    ),

                    const SizedBox(height: 10),

                    CustomButton(
                      text: "Cancel",
                      outlined: true,
                      onPressed: () {
                        Nav.pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.brown),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
