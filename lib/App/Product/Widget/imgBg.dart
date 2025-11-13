import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wworker/Constant/urls.dart';

class CustomImgBg extends StatefulWidget {
  final double height;
  final double borderRadius;
  final String placeholderText;
  final String? defaultImage;
  final String? initialImageUrl; // ✅ added
  final void Function(File?)? onImageSelected;

  const CustomImgBg({
    super.key,
    this.height = 209,
    this.borderRadius = 12,
    this.placeholderText = "Add Design Image",
    this.defaultImage,
    this.initialImageUrl, // ✅ added
    this.onImageSelected,
  });

  @override
  State<CustomImgBg> createState() => _CustomImgBgState();
}

class _CustomImgBgState extends State<CustomImgBg> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      widget.onImageSelected?.call(_selectedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Prioritize user-selected image → initial network image → fallback image
    final imageProvider = _selectedImage != null
        ? FileImage(_selectedImage!)
        : (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty
                  ? NetworkImage(widget.initialImageUrl!)
                  : (widget.defaultImage != null
                        ? NetworkImage(widget.defaultImage!)
                        : const NetworkImage(Urls.woodImg)))
              as ImageProvider;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 56),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_a_photo, size: 66, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  widget.placeholderText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
