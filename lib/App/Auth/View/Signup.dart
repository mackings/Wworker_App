import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/Signin.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/CustomTerms.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/AltSignup.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class Signup extends ConsumerStatefulWidget {
  const Signup({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignupState();
}

class _SignupState extends ConsumerState<Signup> {
  // Controllers
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final companyName = _companyNameController.text.trim();
    final companyEmail = _companyEmailController.text.trim();

    // Only fullname, email, phone, and password are required
    if (fullname.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 8 characters"),
        ),
      );
      return;
    }

    final notifier = ref.read(signupProvider.notifier);
    await notifier.signup(
      fullname: fullname,
      email: email,
      phoneNumber: phone,
      password: password,
      companyName: companyName.isEmpty ? null : companyName,
      companyEmail: companyEmail.isEmpty ? null : companyEmail,
    );

    final state = ref.read(signupProvider);
    state.when(
      data: (data) {
        if (data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signup successful ✅")),
          );
          Nav.push(const Signin());
        }
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$err")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupProvider);
    final isLoading = signupState.isLoading;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(automaticallyImplyLeading: false),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      textAlign: TextAlign.left,
                      title: "Create Account",
                      subtitle:
                          "To create account, provide details, and set password",
                    ),
                    const SizedBox(height: 20),
                    
                    // Full Name (Required)
                    CustomTextField(
                      controller: _fullnameController,
                      label: "Full Name *",
                      hintText: "Enter Full Name",
                    ),
                    const SizedBox(height: 20),
                    
                    // Email (Required)
                    CustomTextField(
                      controller: _emailController,
                      label: "Email *",
                      hintText: "Enter Email Address",
                    ),
                    const SizedBox(height: 20),
                    
                    // Phone (Required)
                    CustomTextField(
                      controller: _phoneController,
                      label: "Phone *",
                      hintText: "Enter Phone Number",
                    ),
                    const SizedBox(height: 20),
                    
                    // Password (Required)
                    CustomTextField(
                      controller: _passwordController,
                      label: "Password *",
                      hintText: "Enter Password (min 8 characters)",
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),
                    
                    // Company Name (Optional)
                    CustomTextField(
                      controller: _companyNameController,
                      label: "Company Name (Optional)",
                      hintText: "Enter Company Name",
                    ),
                    const SizedBox(height: 20),
                    
                    // Company Email (Optional)
                    CustomTextField(
                      controller: _companyEmailController,
                      label: "Company Email (Optional)",
                      hintText: "Enter Company Email",
                    ),
                    const SizedBox(height: 20),
                    
                    const TermsCheckbox(),
                    const SizedBox(height: 40),

                    CustomButton(
                      text: isLoading ? "Signing up..." : "Sign Up",
                      onPressed: () {
                        if (!isLoading) {
                          _handleSignup();
                        }
                      },
                    ),

                    const SizedBox(height: 50),
                    CustomSignupAlt(
                      onLoginTap: () {
                        Nav.push(const Signin());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 🟤 Overlay Loader
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            ),
          ),
      ],
    );
  }
}