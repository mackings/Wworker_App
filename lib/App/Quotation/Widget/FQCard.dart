import 'package:flutter/material.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';


class FirstQuoteCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController busStopController;
  final TextEditingController descriptionController;
  final VoidCallback onContinue;

  const FirstQuoteCard({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.busStopController,
    required this.descriptionController,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quotation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            "Client’s Information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: addressController,
            label: "Address",
            hintText: "E.g K3, plaza, New Garage, Ibadan",
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: busStopController,
            label: "Nearest Bus/Stop",
            hintText: "E.g Alagbe Bus/Stop",
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: phoneController,
            label: "Phone Number",
            hintText: "E.g 07089567473",
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: emailController,
            label: "Email",
            hintText: "E.g admin@sumitnovatrustltd.com",
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: descriptionController,
            label: "Description",
            hintText: "Enter a description",
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "Continue",
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
