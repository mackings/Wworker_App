import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/Api/Provider.dart';
import 'package:wworker/App/Auth/View/Signin.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class Updatepassword extends ConsumerStatefulWidget {
  const Updatepassword({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UpdatepasswordState();
}

class _UpdatepasswordState extends ConsumerState<Updatepassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool isLoading = false;

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirm.isEmpty || password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);

    final response = await ref
        .read(authServiceProvider)
        .resetPassword(password: password);

    setState(() => isLoading = false);

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Password reset successful!"),
        ),
      );
      Nav.push(const Signin());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Reset failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                textAlign: TextAlign.left,
                title: "Create New Password",
                subtitle:
                    "Reset password to quickly calculate your next project",
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                label: "Password",
                hintText: "Enter Password",
                isPassword: true,
              ),

              const SizedBox(height: 30),

              CustomTextField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                hintText: "Enter Password Again",
                isPassword: true,
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: isLoading ? "Resetting..." : "Reset Password",
                onPressed: isLoading ? () {} : _resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
