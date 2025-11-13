import 'package:flutter/material.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class FirstQuoteCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController busStopController;
  final TextEditingController descriptionController;

  const FirstQuoteCard({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.busStopController,
    required this.descriptionController,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Client’s Information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // ✅ Fixed Name Field
          CustomTextField(
            controller: nameController,
            label: "Name",
            hintText: "E.g John Doe",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your name";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ✅ Address
          CustomTextField(
            controller: addressController,
            label: "Address",
            hintText: "E.g K3, plaza, New Garage, Ibadan",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your address";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ✅ Bus Stop
          CustomTextField(
            controller: busStopController,
            label: "Nearest Bus/Stop",
            hintText: "E.g Alagbe Bus/Stop",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter nearest bus/stop";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ✅ Phone
          CustomTextField(
            controller: phoneController,
            label: "Phone Number",
            hintText: "E.g 07089567473",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your phone number";
              } else if (value.length < 10) {
                return "Invalid phone number";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ✅ Email
          CustomTextField(
            controller: emailController,
            label: "Email",
            hintText: "E.g admin@sumitnovatrustltd.com",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your email";
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return "Enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ✅ Description
          CustomTextField(
            controller: descriptionController,
            label: "Description",
            hintText: "Enter a description",
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter a description";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
