import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/ResetPassword.dart';
import 'package:wworker/App/Auth/Widgets/auth_shell.dart';
import 'package:wworker/App/Auth/Widgets/customRecovery.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

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

    if (!mounted) return;
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
        AuthShell(
          title: 'Forgot password?',
          subtitle: 'Choose where we should send your recovery code.',
          icon: Icons.key_outlined,
          children: [
            CustomRecoveryOption(
              title: "Reset via Email",
              subtitle: "Code will be sent to your email address",
              leadingIcon: const Icon(Icons.email_outlined, color: authBrand),
              isSelected: selectedOption == "email",
              onTap: () => setState(() => selectedOption = "email"),
            ),
            const SizedBox(height: 12),
            CustomRecoveryOption(
              title: "Reset via Phone",
              subtitle: "Code will be sent to your phone number",
              leadingIcon: const Icon(Icons.phone_outlined, color: authBrand),
              isSelected: selectedOption == "phone",
              onTap: () => setState(() => selectedOption = "phone"),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: isLoading ? "Sending..." : "Continue",
              borderRadius: 16,
              onPressed: isLoading ? () {} : _handleForgotPassword,
            ),
          ],
        ),
        AuthLoadingOverlay(visible: isLoading),
      ],
    );
  }
}
