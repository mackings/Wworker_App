import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/Signin.dart';
import 'package:wworker/App/Auth/Widgets/auth_shell.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/CustomTerms.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/AltSignup.dart';
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
    if (fullname.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters")),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Signup successful ✅")));
          Nav.push(const Signin());
        }
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$err")));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupProvider);
    final isLoading = signupState.isLoading;

    return Stack(
      children: [
        AuthShell(
          canPop: false,
          title: 'Create account',
          subtitle: 'Set up your workspace details and start managing jobs.',
          icon: Icons.person_add_alt_1_outlined,
          children: [
            CustomTextField(
              controller: _fullnameController,
              label: "Full Name *",
              hintText: "Enter full name",
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: "Email *",
              hintText: "Enter email address",
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: "Phone *",
              hintText: "Enter phone number",
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: "Password *",
              hintText: "Enter password",
              isPassword: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _companyNameController,
              label: "Company Name (Optional)",
              hintText: "Enter company name",
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _companyEmailController,
              label: "Company Email (Optional)",
              hintText: "Enter company email",
            ),
            const SizedBox(height: 16),
            const TermsCheckbox(),
            const SizedBox(height: 24),
            CustomButton(
              text: isLoading ? "Signing up..." : "Sign Up",
              borderRadius: 16,
              onPressed: () {
                if (!isLoading) _handleSignup();
              },
            ),
            const SizedBox(height: 24),
            CustomSignupAlt(
              onLoginTap: () {
                Nav.push(const Signin());
              },
            ),
          ],
        ),
        AuthLoadingOverlay(visible: isLoading),
      ],
    );
  }
}
