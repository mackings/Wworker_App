import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                SizedBox(height: 20),

                CustomTextField(label: "Full Name", hintText: "Enter Fullname"),

                SizedBox(height: 20),
                CustomTextField(
                  label: "Email",
                  hintText: "Enter Email Address",
                ),

                SizedBox(height: 20),
                CustomTextField(label: "Phone", hintText: "Enter Phone Number"),

                SizedBox(height: 20),
                CustomTextField(
                  label: "Password",
                  hintText: "Enter Password",
                  isPassword: true,
                ),

                SizedBox(height: 20),
                TermsCheckbox(),
                SizedBox(height: 20),

                CustomButton(text: "Sign Up", onPressed: () {}),
                SizedBox(height: 20),
                CustomSignupAlt(
                  onLoginTap: () {
                    Nav.push(Signin());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
