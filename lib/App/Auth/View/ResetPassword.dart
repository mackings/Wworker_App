import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/GeneralWidgets/UI/customOTP.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class ResetPassword extends ConsumerStatefulWidget {
  const ResetPassword({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends ConsumerState<ResetPassword> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                CustomText(
                  title: "Enter recovery code",
                  subtitle: "Enter the verification code we just sent to your mail",
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 40),

                CustomOTP()

              ],
            ),
          ),
        ),
      ),
    );
  }
}