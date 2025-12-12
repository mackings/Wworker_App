import 'package:flutter/material.dart';
import 'package:wworker/App/Staffing/Api/staffService.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final companyNameController = TextEditingController();
  final companyEmailController = TextEditingController();
  final companyPhoneController = TextEditingController();
  final companyAddressController = TextEditingController();

  final CompanyService _companyService = CompanyService();
  bool isLoading = false;

  @override
  void dispose() {
    companyNameController.dispose();
    companyEmailController.dispose();
    companyPhoneController.dispose();
    companyAddressController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    // Validate required fields
    if (companyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Company name is required"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _companyService.createCompany(
        companyName: companyNameController.text.trim(),
        companyEmail: companyEmailController.text.trim().isEmpty
            ? null
            : companyEmailController.text.trim(),
        companyPhone: companyPhoneController.text.trim().isEmpty
            ? null
            : companyPhoneController.text.trim(),
        companyAddress: companyAddressController.text.trim().isEmpty
            ? null
            : companyAddressController.text.trim(),
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Company created successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          Nav.pop();
          Nav.pop();
          
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ ${result['message'] ?? 'Failed to create company'}",
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
      appBar: AppBar(
        title: CustomText(title: "Create Company"),
        centerTitle: true,
      ),
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
                    const SizedBox(height: 20),

                    // Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 60,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    CustomText(
                      title: "Let's set up your company",
                      titleFontSize: 24,
                      titleFontWeight: FontWeight.bold,
                    ),

                    const SizedBox(height: 10),

                    CustomText(
                      subtitle:
                          "You'll be able to invite staff members after creating your company.",
                      subtitleColor: Colors.grey,
                    ),

                    const SizedBox(height: 30),

                    // Company Name (Required)
                    CustomTextField(
                      label: "Company Name *",
                      hintText: "Enter your company name",
                      controller: companyNameController,
                    ),
                    const SizedBox(height: 20),

                    // Company Email (Optional)
                    CustomTextField(
                      label: "Company Email (Optional)",
                      hintText: "company@example.com",
                      controller: companyEmailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Company Phone (Optional)
                    CustomTextField(
                      label: "Company Phone (Optional)",
                      hintText: "Enter phone number",
                      controller: companyPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // Company Address (Optional)
                    CustomTextField(
                      label: "Company Address (Optional)",
                      hintText: "Enter company address",
                      controller: companyAddressController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),

                    CustomButton(
                      text: "Create Company",
                      loading: isLoading,
                      onPressed: _createCompany,
                    ),

                    const SizedBox(height: 10),
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
                  child: CircularProgressIndicator(color: Color(0xFF8B4513)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
