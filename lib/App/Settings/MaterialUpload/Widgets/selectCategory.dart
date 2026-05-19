import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/catalog_material_picker.dart';
import 'package:wworker/Constant/colors.dart';

const Color _uploadBg = Color(0xFFFAF7F3);
const Color _uploadInk = Color(0xFF211D1A);
const Color _uploadMuted = Color(0xFF756A61);
const Color _uploadBrand = Color(0xFF8B4513);
const Color _uploadBorder = Color(0xFFE8DED6);
const Color _uploadTint = Color(0xFFFFF3E8);

class SelectMaterialCategoryPage extends StatefulWidget {
  const SelectMaterialCategoryPage({super.key});

  @override
  State<SelectMaterialCategoryPage> createState() =>
      _SelectMaterialCategoryPageState();
}

class _SelectMaterialCategoryPageState
    extends State<SelectMaterialCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _materialService = MaterialService();

  final _nameController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  final _categories = const [
    'Wood',
    'Board',
    'Foam',
    'Fabric',
    'Marble',
    'Hardware',
    'Paint',
    'Adhesive',
    'Nail',
    'Other',
  ];
  final _units = const [
    'Piece',
    'Yard',
    'bag',
    'Pair',
    'Pack',
    'Set',
    'Roll',
    'sqm',
  ];
  final _thicknessUnits = const ['inches', 'mm', 'cm'];
  final _pricingUnits = const [
    'piece',
    'yard',
    'bag',
    'pair',
    'pack',
    'set',
    'roll',
    'sqm',
  ];

  String _category = 'Wood';
  String _unit = 'Piece';
  String _thicknessUnit = 'inches';
  String _pricingUnit = 'piece';
  String? _imagePath;
  Map<String, dynamic>? _selectedCatalogMaterial;
  bool _useCatalog = false;
  bool _submitting = false;
  bool _loadingSubCategories = false;
  List<String> _subCategoryOptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubCategoryOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subCategoryController.dispose();
    _thicknessController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCatalogMaterial() async {
    final selected = await pickSupportedCatalogMaterial(
      context: context,
      materialService: _materialService,
      preferredCategory: _category,
      title: 'Select $_category catalog material',
    );
    if (selected == null) return;

    final unit = (selected['unit'] ?? _unit).toString().trim();
    setState(() {
      _selectedCatalogMaterial = selected;
      _nameController.text = catalogMaterialDisplayName(selected);
      _category = cleanCatalogLabel(
        (selected['category'] ?? _category).toString(),
      );
      _subCategoryController.text = cleanCatalogLabel(
        (selected['subCategory'] ?? '').toString(),
      );
      if (unit.isNotEmpty && _units.contains(unit)) _unit = unit;
      if (selected['thickness'] != null) {
        _thicknessController.text = selected['thickness'].toString();
      }
      final thicknessUnit = (selected['thicknessUnit'] ?? '').toString().trim();
      if (_thicknessUnits.contains(thicknessUnit)) {
        _thicknessUnit = thicknessUnit;
      }
      _pricingUnit = _pricingUnitFromUnit(unit);
    });
    _loadSubCategoryOptions();
  }

  Future<void> _loadSubCategoryOptions() async {
    setState(() => _loadingSubCategories = true);

    final result = await _materialService.getGroupedMaterials(
      category: _category,
      isActive: true,
    );

    if (!mounted) return;

    final options = <String>{};
    if (result['success'] == true && result['data'] is List) {
      for (final categoryItem in result['data'] as List) {
        if (categoryItem is! Map) continue;
        final subCategories = categoryItem['subCategories'];
        if (subCategories is! List) continue;
        for (final subCategoryItem in subCategories) {
          if (subCategoryItem is! Map) continue;
          final value = cleanCatalogLabel(
            (subCategoryItem['subCategory'] ?? '').toString(),
          );
          if (value.isNotEmpty) options.add(value);
        }
      }
    }

    setState(() {
      _subCategoryOptions = options.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _loadingSubCategories = false;
    });
  }

  String _pricingUnitFromUnit(String unit) {
    final normalized = unit.trim().toLowerCase();
    if (_pricingUnits.contains(normalized)) return normalized;
    if (normalized == 'piece') return 'piece';
    if (normalized == 'yard') return 'yard';
    return 'piece';
  }

  Future<void> _submitMaterial() async {
    FocusScope.of(context).unfocus();

    if (_useCatalog && _selectedCatalogMaterial == null) {
      _showMessage('Select a catalog material first.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final price = double.tryParse(_priceController.text.trim());
    final request = _useCatalog
        ? buildCatalogMaterialCreateFields(_selectedCatalogMaterial!)
        : <String, dynamic>{
            'useCatalog': false,
            'name': _nameController.text.trim(),
            'category': _category,
            'subCategory': _subCategoryController.text.trim(),
            'unit': _unit,
          };

    request['unit'] = _unit;
    request['pricingUnit'] = _pricingUnit;
    if (_requiresThickness) {
      request['thickness'] = double.parse(_thicknessController.text.trim());
      request['thicknessUnit'] = _thicknessUnit;
    }
    if (price != null && price > 0) request['pricePerUnit'] = price;
    if (_notesController.text.trim().isNotEmpty) {
      request['notes'] = _notesController.text.trim();
    }
    if (_imagePath != null) request['imagePath'] = _imagePath;

    final result = await _materialService.createMaterial(request);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      _showMessage('Material submitted for approval.');
      Navigator.pop(context);
      return;
    }

    _showMessage(
      result['message']?.toString() ?? 'Failed to submit material.',
      error: true,
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : const Color(0xFF2E7D32),
      ),
    );
  }

  bool get _requiresThickness {
    final normalized = _category.trim().toLowerCase();
    return normalized == 'wood' || normalized == 'board';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _uploadBg,
      appBar: AppBar(
        backgroundColor: _uploadBg,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: _uploadBg,
        foregroundColor: _uploadInk,
        title: Text(
          'Upload Material',
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitMaterial,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsApp.btnColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit for approval',
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildModeSwitch(),
            const SizedBox(height: 12),
            CustomImgBg(
              placeholderText: 'Add Material Image',
              height: 172,
              borderRadius: 20,
              iconSize: 42,
              textSize: 13,
              overlayPadding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 40,
              ),
              selectedImagePath: _imagePath,
              onImageSelected: (image) =>
                  setState(() => _imagePath = image?.path),
            ),
            const SizedBox(height: 12),
            _buildDetailsCard(),
            const SizedBox(height: 12),
            _buildPricingCard(),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _uploadBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _uploadBrand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _uploadBrand,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create company material',
                  style: GoogleFonts.openSans(
                    color: _uploadInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Create a custom material or use the catalog when you need V2 database metadata and dimension rules.',
                  style: GoogleFonts.openSans(
                    color: _uploadMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _uploadBorder),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'Custom',
            icon: Icons.edit_outlined,
            selected: !_useCatalog,
            onTap: () => setState(() => _useCatalog = false),
          ),
          _ModeButton(
            label: 'Catalog',
            icon: Icons.library_books_outlined,
            selected: _useCatalog,
            onTap: () => setState(() => _useCatalog = true),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return _UploadSection(
      title: 'Material details',
      icon: Icons.layers_outlined,
      children: [
        _FieldLabel('Category'),
        _CategoryChips(
          categories: _categories,
          selected: _category,
          onChanged: (value) {
            setState(() {
              _category = value;
              _selectedCatalogMaterial = null;
              if (_useCatalog) _nameController.clear();
              if (!_requiresThickness) _thicknessController.clear();
            });
            _loadSubCategoryOptions();
          },
        ),
        const SizedBox(height: 12),
        if (_useCatalog) ...[
          _CatalogPickerTile(
            selectedName: _selectedCatalogMaterial == null
                ? null
                : catalogMaterialDisplayName(_selectedCatalogMaterial!),
            onTap: _pickCatalogMaterial,
          ),
          const SizedBox(height: 12),
        ],
        _TextInput(
          controller: _nameController,
          label: 'Material name',
          hint: _useCatalog ? 'Pick from catalog' : 'Custom Spray',
          readOnly: _useCatalog,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 12),
        _TextInput(
          controller: _subCategoryController,
          label: 'Sub category',
          hint: _subCategoryOptions.isEmpty
              ? 'Type a new subcategory'
              : 'Select below or type a new one',
          readOnly: _useCatalog,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Sub category is required'
              : null,
        ),
        if (!_useCatalog) ...[
          const SizedBox(height: 8),
          _SubCategorySuggestions(
            options: _subCategoryOptions,
            selected: _subCategoryController.text.trim(),
            loading: _loadingSubCategories,
            onSelected: (value) {
              setState(() => _subCategoryController.text = value);
            },
          ),
        ],
        if (_requiresThickness) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TextInput(
                  controller: _thicknessController,
                  label: 'Thickness',
                  hint: '0.25',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final thickness = double.tryParse(value?.trim() ?? '');
                    if (thickness == null || thickness <= 0) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SelectInput(
                  label: 'Thickness unit',
                  value: _thicknessUnit,
                  items: _thicknessUnits,
                  onChanged: (value) => setState(() => _thicknessUnit = value),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _TextInput(
          controller: _notesController,
          label: 'Notes',
          hint: 'Optional approval notes',
          maxLines: 3,
          validator: (_) => null,
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return _UploadSection(
      title: 'Pricing',
      icon: Icons.payments_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _SelectInput(
                label: 'Unit',
                value: _unit,
                items: _units,
                onChanged: (value) {
                  setState(() {
                    _unit = value;
                    _pricingUnit = _pricingUnitFromUnit(value);
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SelectInput(
                label: 'Pricing unit',
                value: _pricingUnit,
                items: _pricingUnits,
                onChanged: (value) => setState(() => _pricingUnit = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TextInput(
          controller: _priceController,
          label: 'Price per unit',
          hint: '2100',
          keyboardType: TextInputType.number,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return null;
            final price = double.tryParse(text);
            if (price == null || price < 0) return 'Enter a valid price';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Leave price empty only when the material should be reviewed without a price. Quotations will require manual pricing later.',
          style: GoogleFonts.openSans(
            color: const Color(0xFF756A61),
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _UploadSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _UploadSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _uploadBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _uploadBrand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: _uploadBrand),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.openSans(
                  color: _uploadInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _uploadTint : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? _uploadBrand : _uploadMuted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.openSans(
                  color: selected ? _uploadBrand : _uploadMuted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category == selected;
          return ChoiceChip(
            label: Text(category),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => onChanged(category),
            selectedColor: _uploadTint,
            backgroundColor: Colors.white,
            side: BorderSide(color: active ? _uploadBrand : _uploadBorder),
            labelStyle: GoogleFonts.openSans(
              color: active ? _uploadBrand : _uploadMuted,
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}

class _CatalogPickerTile extends StatelessWidget {
  final String? selectedName;
  final VoidCallback onTap;

  const _CatalogPickerTile({required this.selectedName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _uploadBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _uploadBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: _uploadBrand, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedName ?? 'Choose from material database',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.openSans(
                  color: selectedName == null ? _uploadMuted : _uploadInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _uploadMuted),
          ],
        ),
      ),
    );
  }
}

class _SubCategorySuggestions extends StatelessWidget {
  final List<String> options;
  final String selected;
  final bool loading;
  final ValueChanged<String> onSelected;

  const _SubCategorySuggestions({
    required this.options,
    required this.selected,
    required this.loading,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading existing subcategories...',
            style: GoogleFonts.openSans(
              color: _uploadMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (options.isEmpty) {
      return Text(
        'No existing subcategories for this category yet. Type a new one.',
        style: GoogleFonts.openSans(
          color: _uploadMuted,
          fontSize: 12,
          height: 1.35,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing subcategories',
          style: GoogleFonts.openSans(
            color: _uploadMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final active = option.toLowerCase() == selected.toLowerCase();
            return ChoiceChip(
              label: Text(option),
              selected: active,
              showCheckmark: false,
              onSelected: (_) => onSelected(option),
              selectedColor: _uploadTint,
              backgroundColor: Colors.white,
              side: BorderSide(color: active ? _uploadBrand : _uploadBorder),
              labelStyle: GoogleFonts.openSans(
                color: active ? _uploadBrand : _uploadMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.openSans(
          color: _uploadMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  const _TextInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.openSans(
        color: _uploadInk,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(label: label, hint: hint),
    );
  }
}

class _SelectInput extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _SelectInput({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _inputDecoration(label: label, hint: label),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.openSans(
                  color: _uploadInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    labelStyle: GoogleFonts.openSans(
      color: _uploadMuted,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: GoogleFonts.openSans(
      color: _uploadMuted.withValues(alpha: 0.55),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _uploadBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _uploadBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _uploadBrand, width: 1.3),
    ),
  );
}
