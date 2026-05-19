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
    final displayName = _capitalizeFirst(
      name.isEmpty ? "Untitled product" : name,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 360;
        final imageSize = isTight ? 70.0 : 82.0;
        final buttonWidth = isTight ? 74.0 : 86.0;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: EdgeInsets.all(isTight ? 10 : 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF7F0) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFB7835E)
                      : const Color(0xFFE8DED6),
                  width: isSelected ? 1.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
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
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF211D1A),
                            fontSize: isTight ? 13 : 14,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productId.isEmpty ? "No product ID" : productId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            color: const Color(0xFF756A61),
                            fontSize: isTight ? 10.5 : 11,
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

  String _capitalizeFirst(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const _ImageFallback(isLoading: true);
                },
                errorBuilder: (_, __, ___) => const _ImageFallback(),
              )
            : const _ImageFallback(),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final bool isLoading;

  const _ImageFallback({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8DED6)),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFFB7835E),
                size: 23,
              ),
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
        borderRadius: BorderRadius.circular(999),
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isSelected ? "Selected" : "Select",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.openSans(
          color: Colors.white,
          fontSize: compact ? 12 : 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
