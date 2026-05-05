import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExistingProductCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String productId;
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const ExistingProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.productId,
    required this.category,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 360;
        final imageSize = isTight ? 62.0 : 70.0;
        final buttonWidth = isTight ? 82.0 : 96.0;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: EdgeInsets.all(isTight ? 10 : 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF7F0) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFB7835E)
                      : const Color(0xFFE8DED6),
                  width: isSelected ? 1.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _ProductImage(imageUrl: imageUrl, size: imageSize),
                  SizedBox(width: isTight ? 9 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? "Untitled product" : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF211D1A),
                            fontSize: isTight ? 13.5 : 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productId.isEmpty ? "No product ID" : productId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF302E2E),
                            fontSize: isTight ? 11 : 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _Tag(
                          text: category.isEmpty ? "Uncategorized" : category,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isTight ? 8 : 10),
                  _SelectButton(
                    isSelected: isSelected,
                    width: buttonWidth,
                    compact: isTight,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _ProductImage({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFFAF7F3),
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ImageFallback(),
              )
            : const _ImageFallback(),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFFB7835E),
        size: 24,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.openSans(
          color: const Color(0xFF756A61),
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  final bool isSelected;
  final double width;
  final bool compact;

  const _SelectButton({
    required this.isSelected,
    required this.width,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: compact ? 36 : 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFB7835E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSelected ? "Selected" : "Select",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.openSans(
          color: Colors.white,
          fontSize: compact ? 12 : 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
