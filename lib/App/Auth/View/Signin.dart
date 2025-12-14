import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/Signup.dart';
import 'package:wworker/App/Auth/View/resetHome.dart';
import 'package:wworker/App/Staffing/View/Selector.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/AltSignIn.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';




class Signin extends ConsumerStatefulWidget {
  const Signin({super.key});

  @override
  ConsumerState<Signin> createState() => _SigninState();
}

class _SigninState extends ConsumerState<Signin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSignin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    final notifier = ref.read(signinProvider.notifier);
    await notifier.signin(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final signinState = ref.watch(signinProvider);

    ref.listen(signinProvider, (prev, next) {
      next.when(
        data: (data) async {
          if (data["success"] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data["message"] ?? "Signed in successfully"),
                backgroundColor: Colors.green,
              ),
            );

            // Check if user has multiple companies
            final userData = data["data"]?["user"];
            if (userData != null) {
              final companies = userData["companies"] as List?;
              final activeCompanyIndex = userData["activeCompanyIndex"] ?? 0;

              if (companies != null && companies.isNotEmpty) {
                // ✅ Filter out companies with revoked access
                final accessibleCompanies = companies
                    .where((company) => company['accessGranted'] == true)
                    .toList();

                if (accessibleCompanies.isEmpty) {
                  // ✅ No accessible companies - should not happen due to backend check
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("You don't have access to any company. Contact support."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                if (accessibleCompanies.length > 1) {
                  // User has multiple accessible companies - show selection screen
                  Nav.pushReplacement(
                    CompanySelectionScreen(
                      companies: accessibleCompanies,
                      currentIndex: activeCompanyIndex,
                    ),
                  );
                } else {
                  // User has single accessible company - go to dashboard
                  Nav.pushReplacement(const DashboardScreen());
                }
              } else {
                // No companies - go to dashboard anyway
                Nav.pushReplacement(const DashboardScreen());
              }
            } else {
              // No user data - go to dashboard anyway
              Nav.pushReplacement(const DashboardScreen());
            }
          }
        },
        loading: () {},
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$err"),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
      );
    });

    final isLoading = signinState.isLoading;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(automaticallyImplyLeading: false),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    textAlign: TextAlign.left,
                    title: "Welcome Back",
                    subtitle: "Log in to quickly calculate your next project",
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _emailController,
                    label: "Email",
                    hintText: "Enter Email Address",
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    label: "Password",
                    hintText: "Enter Password",
                    isPassword: true,
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: isLoading ? "Signing in..." : "Sign In",
                    onPressed: isLoading ? () {} : _handleSignin,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Nav.push(const ResetHome()),
                      child: CustomText(
                        subtitle: "Forgot password?",
                        subtitleColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomSigninAlt(
                    onLoginTap: () {
                      Nav.pushReplacement(const Signup());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}