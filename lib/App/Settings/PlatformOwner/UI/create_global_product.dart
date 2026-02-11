import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class CreateGlobalProduct extends ConsumerStatefulWidget {
  const CreateGlobalProduct({super.key});

  @override
  ConsumerState<CreateGlobalProduct> createState() =>
      _CreateGlobalProductState();
}

class _CreateGlobalProductState extends ConsumerState<CreateGlobalProduct> {
  final PlatformOwnerService _service = PlatformOwnerService();
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final subCategoryController = TextEditingController();
  final descController = TextEditingController();

  String? selectedCategory;
  String? imagePath;
  bool isLoading = false;

  final List<String> _categories = const ["Wood", "Foam", "Plank", "Others"];

  Future<void> _createGlobalProduct() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _service.createGlobalProduct(
        name: nameController.text.trim(),
        category: selectedCategory ?? '',
        subCategory: subCategoryController.text.trim(),
        description: descController.text.trim(),
        imagePath: imagePath,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Global product created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Nav.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentMaxWidth = screenWidth > 520 ? 520.0 : screenWidth;

    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create Global Product',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Form(
                key: _formKey,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildInfoStrip(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                title: 'Product Image',
                                subtitle: 'Optional but recommended',
                                icon: Icons.image_outlined,
                              ),
                              const SizedBox(height: 12),
                              CustomImgBg(
                                placeholderText: 'Add Product Image',
                                onImageSelected: (image) {
                                  setState(() => imagePath = image?.path);
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildSectionTitle(
                                title: 'Basics',
                                subtitle:
                                    'Core details used across the platform',
                                icon: Icons.inventory_2_outlined,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                label: 'Product name',
                                hintText: 'Enter product name',
                                controller: nameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Product name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Category',
                                hintText: 'Select a category',
                                isDropdown: true,
                                dropdownItems: _categories,
                                value: selectedCategory,
                                onChanged: (value) {
                                  setState(() => selectedCategory = value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Category is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Sub category',
                                hintText: 'Enter subcategory (optional)',
                                controller: subCategoryController,
                              ),
                              const SizedBox(height: 20),
                              _buildSectionTitle(
                                title: 'Description',
                                subtitle:
                                    'Optional details to help teams search',
                                icon: Icons.notes_outlined,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                label: 'Description',
                                hintText:
                                    'Enter product description (optional)',
                                controller: descController,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Create Global Product',
                                onPressed: _createGlobalProduct,
                                loading: isLoading,
                              ),
                              const SizedBox(height: 10),
                              CustomButton(
                                text: 'Cancel',
                                outlined: true,
                                onPressed: () => Nav.pop(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorsApp.btnColor, ColorsApp.btnColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorsApp.btnColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Product',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a shared catalog item visible to every company.',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorsApp.btnColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorsApp.btnColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 18,
              color: ColorsApp.btnColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Global products appear in every company catalog and stay editable by platform owners only.',
              style: GoogleFonts.openSans(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorsApp.btnColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: ColorsApp.btnColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorsApp.textColor,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    subCategoryController.dispose();
    descController.dispose();
    super.dispose();
  }
}
