import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/Constant/colors.dart';


class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double borderRadius;
  final bool outlined;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = 327,
    this.borderRadius = 8,
    this.outlined = false,
    this.icon,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color btnBgColor =
        outlined ? Colors.transparent : (backgroundColor ?? ColorsApp.btnColor);
    final Color btnTextColor =
        outlined ? (textColor ?? ColorsApp.btnColor) : (textColor ?? Colors.white);
    final Color btnBorderColor =
        outlined ? (borderColor ?? ColorsApp.btnColor) : Colors.transparent;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width == 327 ? MediaQuery.of(context).size.width - 35 : width,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: btnBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: btnBorderColor, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? btnTextColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: GoogleFonts.openSans(
                color: btnTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
