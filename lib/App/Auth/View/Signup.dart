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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    final notifier = ref.read(signupProvider.notifier);
    await notifier.signup(
      email: email,
      phoneNumber: phone,
      password: password,
    );

    final state = ref.read(signupProvider);
    state.when(
      data: (data) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful ✅")),
        );
        Nav.push(const Signin());
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
                    CustomTextField(
                      controller: _emailController,
                      label: "Email",
                      hintText: "Enter Email Address",
                    ),

                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _phoneController,
                      label: "Phone",
                      hintText: "Enter Phone Number",
                    ),

                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: "Password",
                      hintText: "Enter Password",
                      isPassword: true,
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
              child: CircularProgressIndicator(
                color: Color(0xFF8B4513),
              ),
            ),
          ),
      ],
    );
  }
}
