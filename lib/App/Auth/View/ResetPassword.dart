import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/updatePassword.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customOTP.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

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
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const CustomText(
                title: "Enter recovery code",
                subtitle:
                    "Enter the verification code we just sent to your mail",
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 40),
              CustomOTP(
                onCompleted: _verifyOtp,
                onResend: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("OTP resent")));
                },
              ),
              if (isVerifying)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
