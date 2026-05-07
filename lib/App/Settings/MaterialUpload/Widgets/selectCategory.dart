import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/catalog_material_picker.dart';
import 'package:wworker/Constant/colors.dart';

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
  final _units = const ['Piece', 'bag', 'Pair', 'Pack', 'Set', 'Roll', 'sqm'];
  final _thicknessUnits = const ['inches', 'mm', 'cm'];
  final _pricingUnits = const [
    'piece',
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
  }

  String _pricingUnitFromUnit(String unit) {
    final normalized = unit.trim().toLowerCase();
    if (_pricingUnits.contains(normalized)) return normalized;
    if (normalized == 'piece') return 'piece';
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
      backgroundColor: const Color(0xFFFAF7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F3),
        elevation: 0,
        surfaceTintColor: const Color(0xFFFAF7F3),
        foregroundColor: const Color(0xFF211D1A),
        title: Text(
          'Upload Material',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: SafeArea(
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
                  borderRadius: BorderRadius.circular(8),
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
                        fontWeight: FontWeight.w700,
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
            const SizedBox(height: 14),
            _buildModeSwitch(),
            const SizedBox(height: 14),
            CustomImgBg(
              placeholderText: 'Add Material Image',
              selectedImagePath: _imagePath,
              onImageSelected: (image) =>
                  setState(() => _imagePath = image?.path),
            ),
            const SizedBox(height: 14),
            _buildDetailsCard(),
            const SizedBox(height: 14),
            _buildPricingCard(),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D241E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create company material',
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Create a custom material or use the catalog when you need V2 database metadata and dimension rules.',
                  style: GoogleFonts.openSans(
                    color: Colors.white.withValues(alpha: 0.72),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DED6)),
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
          hint: 'Auto base, Iroko, Spray paint',
          readOnly: _useCatalog,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Sub category is required'
              : null,
        ),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: const Color(0xFF8B4513)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.openSans(
                  color: const Color(0xFF211D1A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF3E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFF8B4513)
                    : const Color(0xFF756A61),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.openSans(
                  color: selected
                      ? const Color(0xFF8B4513)
                      : const Color(0xFF756A61),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
      height: 38,
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
            selectedColor: const Color(0xFFFFF3E8),
            backgroundColor: const Color(0xFFFAF7F3),
            side: BorderSide(
              color: active ? const Color(0xFF8B4513) : const Color(0xFFE8DED6),
            ),
            labelStyle: GoogleFonts.openSans(
              color: active ? const Color(0xFF8B4513) : const Color(0xFF756A61),
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8DED6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF8B4513), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedName ?? 'Choose from material database',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.openSans(
                  color: selectedName == null
                      ? const Color(0xFF756A61)
                      : const Color(0xFF211D1A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF756A61)),
          ],
        ),
      ),
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
          color: const Color(0xFF756A61),
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
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
    fillColor: const Color(0xFFFAF7F3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE8DED6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE8DED6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF8B4513)),
    ),
  );
}
