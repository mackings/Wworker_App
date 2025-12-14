import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/AuthService.dart';
import 'package:wworker/App/Staffing/Api/staffService.dart';
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
  final positionController = TextEditingController(); // ✅ Changed to TextEditingController
  
  final CompanyService _companyService = CompanyService();
  
  bool isLoading = false;
  String? selectedRole;

  // ✅ List of roles
  final List<String> roles = ["admin", "staff"];

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
        positionController.text.isEmpty) { // ✅ Changed validation
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
      final result = await _companyService.inviteStaff(
        fullname: fullnameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        role: selectedRole!,
        position: positionController.text.trim(), // ✅ Using text input
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        if (mounted) {
          // Show temp password if returned (optional)
          final tempPassword = result['data']?['tempPassword'];
          
          ScaffoldMessenger.of(context).showSnackBar(
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

          // Navigate back
          Nav.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ ${result['message'] ?? 'Failed to invite staff'}"),
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
                      subtitle: "Create a new staff account. They'll receive login credentials via email.",
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
                      hintText: "Enter position (e.g., Cabinet Maker, Sales Manager)",
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