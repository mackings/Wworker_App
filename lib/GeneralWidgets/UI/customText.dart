import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/Constant/colors.dart';


class CustomTextWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final TextAlign textAlign;
  final double titleFontSize;
  final double subtitleFontSize;
  final FontWeight titleFontWeight;
  final FontWeight subtitleFontWeight;
  final Color? titleColor;
  final Color? subtitleColor;
  final double spacing;
  final String titleFont;
  final String subtitleFont;

  const CustomTextWidget({
    super.key,
    this.title,
    this.subtitle,
    this.textAlign = TextAlign.center,
    this.titleFontSize = 20,
    this.subtitleFontSize = 14,
    this.titleFontWeight = FontWeight.w500,
    this.subtitleFontWeight = FontWeight.w400,
    this.titleColor,
    this.subtitleColor,
    this.spacing = 8,
    this.titleFont = 'Poppins',
    this.subtitleFont = 'Open Sans',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : textAlign == TextAlign.right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center,
      children: [
        if (title != null)
          Text(
            title!,
            textAlign: textAlign,
            style: GoogleFonts.getFont(
              titleFont,
              color: titleColor ?? ColorsApp.textColor,
              fontSize: titleFontSize,
              fontWeight: titleFontWeight,
              height: 1.2,
            ),
          ),
        if (subtitle != null) SizedBox(height: spacing),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: textAlign,
            style: GoogleFonts.getFont(
              subtitleFont,
              color: subtitleColor ?? ColorsApp.textColor.withOpacity(0.9),
              fontSize: subtitleFontSize,
              fontWeight: subtitleFontWeight,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}
