import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final passwordController = TextEditingController();

  final StaffService _staffService = StaffService();
  bool isLoading = false;
  bool obscurePassword = true;
  String? selectedPosition;

  // ✅ List of positions in a woodwork company
  final List<String> positions = [
    "Workshop Manager",
    "Production Supervisor",
    "Cabinet Maker",
    "Furniture Designer",
    "Wood Finisher",
    "CNC Operator",
    "Sales Manager",
    "Sales Representative",
    "Quality Control Inspector",
    "Warehouse Manager",
    "Delivery Driver",
    "Administrative Assistant",
  ];

  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _addStaff() async {
    // Validate fields
    if (fullnameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedPosition == null ||
        passwordController.text.isEmpty) {
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

    // Validate password length
    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 8 characters long"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _staffService.createStaff(
        fullname: fullnameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        position: selectedPosition!,
        password: passwordController.text,
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Staff added successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          // Clear fields
          fullnameController.clear();
          emailController.clear();
          phoneController.clear();
          passwordController.clear();
          setState(() => selectedPosition = null);

          // Navigate back or to staff list
          Nav.pop();
          // OR navigate to staff list
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (_) => const StaffListScreen()),
          // );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ ${result['message'] ?? 'Failed to add staff'}"),
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
                  children: [
                    CustomTextField(
                      label: "Fullname",
                      hintText: "Enter full name",
                      controller: fullnameController,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: "Email",
                      hintText: "Enter email address",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: "Phone number",
                      hintText: "Enter phone number",
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // ✅ Position Dropdown
                    CustomTextField(
                      label: "Position",
                      hintText: "Select position/role",
                      isDropdown: true,
                      dropdownItems: positions,
                      value: selectedPosition,
                      onChanged: (value) {
                        setState(() {
                          selectedPosition = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: "Password",
                      hintText: "Enter password (min 8 characters)",
                      controller: passwordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 40),

                    CustomButton(
                      text: "Add Staff",
                      loading: isLoading,
                      onPressed: _addStaff,
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
