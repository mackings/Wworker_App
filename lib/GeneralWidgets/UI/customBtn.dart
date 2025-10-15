import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/Constant/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = 327,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: MediaQuery.of(context).size.width -35,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: ColorsApp.btnColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.openSans(
              color: ColorsApp.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
