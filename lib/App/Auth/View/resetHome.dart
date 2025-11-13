import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/ResetPassword.dart';
import 'package:wworker/App/Auth/Widgets/customRecovery.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class ResetHome extends ConsumerStatefulWidget {
  const ResetHome({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ResetHomeState();
}

class _ResetHomeState extends ConsumerState<ResetHome> {
  String selectedOption = "";
  bool isLoading = false;

  Future<void> _handleForgotPassword() async {
    if (selectedOption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a recovery method")),
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await ref
        .read(authServiceProvider)
        .forgotPassword(method: selectedOption);

    setState(() => isLoading = false);

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Email sent!")),
      );
      Nav.push(const ResetPassword());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to send reset link"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const CustomText(
                      title: "Forgot Password?",
                      subtitle:
                          "Please select option to send link to reset password",
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 40),

                    CustomRecoveryOption(
                      title: "Reset via Email",
                      subtitle: "Code will be sent to your email address",
                      leadingIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF302E2E),
                      ),
                      isSelected: selectedOption == "email",
                      onTap: () => setState(() => selectedOption = "email"),
                    ),

                    const SizedBox(height: 12),

                    CustomRecoveryOption(
                      title: "Reset via Phone",
                      subtitle: "Code will be sent to your phone number",
                      leadingIcon: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF302E2E),
                      ),
                      isSelected: selectedOption == "phone",
                      onTap: () => setState(() => selectedOption = "phone"),
                    ),

                    const SizedBox(height: 40),

                    CustomButton(
                      text: isLoading ? "Sending..." : "Continue",
                      onPressed: isLoading ? () {} : _handleForgotPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 🌀 Loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
      ],
    );
  }
}
