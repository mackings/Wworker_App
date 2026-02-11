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
  final String? selectedImagePath; // optional: let parent control preview
  final void Function(File?)? onImageSelected;

  const CustomImgBg({
    super.key,
    this.height = 209,
    this.borderRadius = 12,
    this.placeholderText = "Add Design Image",
    this.defaultImage,
    this.initialImageUrl, // ✅ added
    this.selectedImagePath,
    this.onImageSelected,
  });

  @override
  State<CustomImgBg> createState() => _CustomImgBgState();
}

class _CustomImgBgState extends State<CustomImgBg> {
  File? _selectedImage;

  File? _resolveSelectedFile() {
    if (_selectedImage != null) return _selectedImage;
    final p = widget.selectedImagePath;
    if (p == null || p.isEmpty) return null;
    final f = File(p);
    if (!f.existsSync()) return null;
    return f;
  }

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
    // ✅ Prioritize selected file (internal or controlled) → initial network image → fallback image
    final selectedFile = _resolveSelectedFile();
    final imageProvider = selectedFile != null
        ? FileImage(selectedFile)
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
        padding: selectedFile == null
            ? const EdgeInsets.symmetric(horizontal: 64, vertical: 56)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
        child: selectedFile == null
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_a_photo,
                        size: 66,
                        color: Colors.white,
                      ),
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
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
