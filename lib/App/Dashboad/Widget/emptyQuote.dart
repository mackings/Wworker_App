import 'package:flutter/material.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class CustomEmptyQuotes extends StatelessWidget {
  final String title;
  final String buttonText;
  final String emptyMessage;
  final VoidCallback? onButtonTap;
  final Widget? content;

  const CustomEmptyQuotes({
    super.key,
    required this.title,
    required this.buttonText,
    required this.emptyMessage,
    this.onButtonTap,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(title: title, titleFontSize: 17),

            GestureDetector(
              onTap: onButtonTap,
              child: CustomText(subtitle: buttonText),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Card Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD3D3D3)),
          ),
          child:
              content ??
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 56,
                    color: Color(0xFF8B4513),
                  ),
                  const SizedBox(height: 16),

                  CustomText(
                    subtitle: emptyMessage,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
        ),
      ],
    );
  }
}
