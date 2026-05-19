import 'package:flutter/material.dart';

class FirstQuoteCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController busStopController;

  const FirstQuoteCard({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.busStopController,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DED6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Client’s Information",
            style: TextStyle(
              color: Color(0xFF211D1A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Fixed Name Field
          _ClientInfoField(
            controller: nameController,
            label: "Name",
            hintText: "E.g John Doe",
            icon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your name";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // ✅ Address
          _ClientInfoField(
            controller: addressController,
            label: "Address",
            hintText: "E.g K3, plaza, New Garage, Ibadan",
            icon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your address";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // ✅ Bus Stop
          _ClientInfoField(
            controller: busStopController,
            label: "Nearest Bus/Stop",
            hintText: "E.g Alagbe Bus/Stop",
            icon: Icons.signpost_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter nearest bus/stop";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // ✅ Phone
          _ClientInfoField(
            controller: phoneController,
            label: "Phone Number",
            hintText: "E.g 07089567473",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your phone number";
              } else if (value.length < 10) {
                return "Invalid phone number";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // ✅ Email
          _ClientInfoField(
            controller: emailController,
            label: "Email",
            hintText: "E.g admin@sumitnovatrustltd.com",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
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
        ],
      ),
    );
  }
}

class _ClientInfoField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  const _ClientInfoField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF756A61),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Color(0xFF211D1A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: Icon(icon, color: const Color(0xFF756A61), size: 20),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8DED6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF8B4513),
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
