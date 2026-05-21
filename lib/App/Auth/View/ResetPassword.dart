import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/updatePassword.dart';
import 'package:wworker/App/Auth/Widgets/auth_shell.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customOTP.dart';

class ResetPassword extends ConsumerStatefulWidget {
  const ResetPassword({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends ConsumerState<ResetPassword> {
  bool isVerifying = false;

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return; // 🧠 Guard: only verify when 6 digits entered

    setState(() => isVerifying = true);

    final response = await ref.read(authServiceProvider).verifyOtp(otp: otp);

    if (!mounted) return;
    setState(() => isVerifying = false);

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "OTP Verified")),
      );
      Nav.push(const Updatepassword());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Invalid OTP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthShell(
          title: 'Enter recovery code',
          subtitle: 'Enter the verification code we sent to your email.',
          icon: Icons.password_outlined,
          children: [
            CustomOTP(
              onCompleted: _verifyOtp,
              onResend: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("OTP resent")));
              },
            ),
          ],
        ),
        AuthLoadingOverlay(visible: isVerifying),
      ],
    );
  }
}
