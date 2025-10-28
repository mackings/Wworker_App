import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool isDropdown;
  final List<String>? dropdownItems;
  final ValueChanged<String?>? onChanged;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final bool enabled;
  final int? maxLines;
  final FormFieldValidator<String>? validator;
  final String? value; // ✅ Added for dropdown initial value

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText = '',
    this.controller,
    this.isPassword = false,
    this.isDropdown = false,
    this.dropdownItems,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.enabled = true,
    this.maxLines,
    this.validator,
    this.value, // ✅ Added to constructor
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  IconData? _getIcon() {
    final labelLower = widget.label.toLowerCase();

    if (widget.isPassword) return Icons.lock_outline;
    if (widget.isDropdown) return Icons.list_alt;
    if (labelLower.contains('phone')) return Icons.phone;
    if (labelLower.contains('email')) return Icons.email_outlined;
    if (labelLower.contains('name')) return Icons.person_outline;
    if (labelLower.contains('address')) return Icons.home_outlined;

    return Icons.text_fields;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title: widget.label,
          titleFontSize: 16,
          titleFontWeight: FontWeight.w400,
          titleColor: const Color(0xFF7B7B7B),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: (widget.maxLines != null && widget.maxLines! > 1) ? null : 55,
          decoration: ShapeDecoration(
            color: const Color.fromARGB(255, 241, 238, 238),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: widget.isDropdown ? _buildDropdownField() : _buildTextField(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Center(
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        obscureText: widget.isPassword ? _obscureText : false,
        textAlign: widget.textAlign,
        enabled: widget.enabled,
        textAlignVertical: TextAlignVertical.center,
        maxLines: widget.maxLines ?? 1,
        style: GoogleFonts.openSans(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.openSans(
            fontSize: 16,
            color: const Color(0xFF7B7B7B),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon: widget.isPassword
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF7B7B7B),
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                    const SizedBox(width: 4),
                    Icon(_getIcon(), color: const Color(0xFF7B7B7B)),
                  ],
                )
              : Icon(_getIcon(), color: const Color(0xFF7B7B7B)),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: widget.value, // ✅ Use preselected value if provided
      validator: widget.validator,
      items: widget.dropdownItems
          ?.map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.openSans(
          fontSize: 16,
          color: const Color(0xFF7B7B7B),
        ),
        border: InputBorder.none,
        suffixIcon: const Icon(
          Icons.arrow_drop_down,
          color: Color(0xFF7B7B7B),
        ),
      ),
    );
  }
}
