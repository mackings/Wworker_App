import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/Signup.dart';
import 'package:wworker/App/Auth/View/resetHome.dart';
import 'package:wworker/App/Auth/Widgets/auth_shell.dart';
import 'package:wworker/App/Staffing/View/Selector.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/AltSignIn.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class Signin extends ConsumerStatefulWidget {
  final String? sessionMessage;

  const Signin({super.key, this.sessionMessage});

  @override
  ConsumerState<Signin> createState() => _SigninState();
}

class _SigninState extends ConsumerState<Signin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.sessionMessage != null && widget.sessionMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Required'),
            content: Text(widget.sessionMessage!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _handleSignin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
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
                      content: Text(
                        "You don't have access to any company. Contact support.",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                if (accessibleCompanies.length > 1) {
                  Nav.pushReplacement(
                    CompanySelectionScreen(
                      companies: accessibleCompanies,
                      currentIndex: activeCompanyIndex,
                    ),
                  );
                } else {
                  Nav.pushReplacement(
                    CompanySelectionScreen(
                      companies: accessibleCompanies,
                      currentIndex: 0,
                    ),
                  );
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
            SnackBar(content: Text("$err"), backgroundColor: Colors.redAccent),
          );
        },
      );
    });

    final isLoading = signinState.isLoading;

    return Stack(
      children: [
        AuthShell(
          canPop: false,
          title: 'Welcome back',
          subtitle:
              'Sign in to manage quotations, orders, invoices, and materials.',
          icon: Icons.lock_open_outlined,
          children: [
            CustomTextField(
              controller: _emailController,
              label: "Email",
              hintText: "Enter email address",
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: "Password",
              hintText: "Enter password",
              isPassword: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: isLoading ? "Signing in..." : "Sign In",
              borderRadius: 16,
              onPressed: isLoading ? () {} : _handleSignin,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Nav.push(const ResetHome()),
                child: const Text("Forgot password?"),
              ),
            ),
            const SizedBox(height: 8),
            CustomSigninAlt(
              onLoginTap: () {
                Nav.pushReplacement(const Signup());
              },
            ),
          ],
        ),
        AuthLoadingOverlay(visible: isLoading),
      ],
    );
  }
}
