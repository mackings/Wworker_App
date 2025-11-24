import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/Constant/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  // Sizes
  final double width;
  final double height;
  final double padding;
  final double textSize;
  final double iconSize;

  final double borderRadius;
  final bool outlined;
  final bool loading;

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
    this.height = 56,                // ✅ Default button height
    this.padding = 16,               // ✅ Default internal padding
    this.textSize = 16,              // ✅ Default text size
    this.iconSize = 20,              // ✅ Default icon size
    this.borderRadius = 8,
    this.outlined = false,
    this.loading = false,
    this.icon,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color btnBgColor = outlined
        ? Colors.transparent
        : (backgroundColor ?? ColorsApp.btnColor);

    final Color btnTextColor = outlined
        ? (textColor ?? ColorsApp.btnColor)
        : (textColor ?? Colors.white);

    final Color btnBorderColor = outlined
        ? (borderColor ?? ColorsApp.btnColor)
        : Colors.transparent;

    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        width: width == 327 ? MediaQuery.of(context).size.width - 35 : width,
        height: height, // ✅ Height now customizable
        padding: EdgeInsets.all(padding), // ✅ Padding customizable
        decoration: ShapeDecoration(
          color: btnBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: btnBorderColor, width: 2),
          ),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: btnTextColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: iconColor ?? btnTextColor,
                        size: iconSize, // ✅ Custom icon size
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.openSans(
                        color: btnTextColor,
                        fontSize: textSize, // ✅ Custom text size
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
