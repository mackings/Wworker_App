import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Auth/View/Signup.dart';
import 'package:wworker/App/Auth/View/resetHome.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/AltSignIn.dart';
import 'package:wworker/GeneralWidgets/UI/DashConfig.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';




class Signin extends ConsumerStatefulWidget {
  const Signin({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SigninState();
}

class _SigninState extends ConsumerState<Signin> {
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
                  title: "Welcome Back",
                  subtitle:
                      "log in today to quickly calculate your next project",
                ),

                SizedBox(height: 20),

                CustomTextField(
                  label: "Email",
                  hintText: "Enter Email Address",
                ),

                SizedBox(height: 20),

                CustomTextField(
                  label: "Password",
                  hintText: "Enter Password",
                  isPassword: true,
                ),

                SizedBox(height: 40),

                CustomButton(
                  text: "Sign In",
                  onPressed: () {
                    Nav.push(DashboardScreen());
                  },
                ),

                SizedBox(height: 20),
                
                Align(
                  alignment: AlignmentGeometry.bottomRight,
                  child: GestureDetector(
                    onTap: () {
                      Nav.push(ResetHome());
                    },
                    child: CustomText(
                      subtitle: "Forgot password",
                      subtitleColor: Colors.blue,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                CustomSigninAlt(
                  onLoginTap: () {
                    Nav.pushReplacement(Signup());
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
