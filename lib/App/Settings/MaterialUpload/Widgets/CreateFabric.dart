import 'package:flutter/material.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';
import 'package:wworker/App/Settings/MaterialUpload/Widgets/catalog_material_picker.dart';
import 'package:wworker/Constant/colors.dart';

class CreateFabricMaterialPage extends StatefulWidget {
  const CreateFabricMaterialPage({super.key});

  @override
  State<CreateFabricMaterialPage> createState() =>
      _CreateFabricMaterialPageState();
}

class _CreateFabricMaterialPageState extends State<CreateFabricMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _pricingUnit = 'piece';
  String? _imagePath;
  Map<String, dynamic>? _selectedCatalogMaterial;
  bool _useCatalog = true;
  bool isCreating = false;

  Future<void> _createMaterial() async {
    if (_useCatalog && _selectedCatalogMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supported catalog material')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isCreating = true);

    final baseRequest = _useCatalog
        ? buildCatalogMaterialCreateFields(_selectedCatalogMaterial!)
        : <String, dynamic>{
            'useCatalog': false,
            'name': _nameController.text.trim(),
            'category': 'Fabric',
          };

    final request = {
      ...baseRequest,
      if (_imagePath != null) 'imagePath': _imagePath,
      'pricePerUnit': double.parse(_priceController.text),
      'pricingUnit': _pricingUnit,
      if (_notesController.text.isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    final result = await _materialService.createMaterial(request);

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material submitted for review')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to create material'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickCatalogMaterial() async {
    final selected = await pickSupportedCatalogMaterial(
      context: context,
      materialService: _materialService,
      preferredCategory: 'Fabric',
      title: 'Select Fabric Catalog Material',
    );
    if (selected == null) return;
    setState(() {
      _selectedCatalogMaterial = selected;
      _nameController.text = catalogMaterialDisplayName(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: const Text(
          "Create Fabric Material",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomImgBg(
              placeholderText: 'Add Material Image (Optional)',
              selectedImagePath: _imagePath,
              onImageSelected: (image) {
                setState(() => _imagePath = image?.path);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE91E63).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.checkroom, color: const Color(0xFFE91E63)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fabric materials are priced per piece or per meter.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard([
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Supported Catalog (Recommended)'),
                subtitle: const Text(
                  'Turn this off to enter a custom material name (non-catalog).',
                ),
                value: _useCatalog,
                onChanged: (v) {
                  setState(() {
                    _useCatalog = v;
                    if (!_useCatalog) {
                      _selectedCatalogMaterial = null;
                    } else if (_selectedCatalogMaterial != null) {
                      _nameController.text = catalogMaterialDisplayName(
                        _selectedCatalogMaterial!,
                      );
                    }
                  });
                },
              ),
              TextFormField(
                controller: _nameController,
                readOnly: _useCatalog,
                decoration: const InputDecoration(
                  labelText: 'Fabric Name *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Leather, Velvet, Ankara',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _useCatalog ? _pickCatalogMaterial : null,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  _selectedCatalogMaterial == null
                      ? 'Select From Supported Catalog'
                      : 'Change Catalog Material',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                  prefixText: '₦',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _pricingUnit,
                decoration: const InputDecoration(
                  labelText: 'Pricing Unit *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'piece', child: Text('Per Piece')),
                  DropdownMenuItem(value: 'meter', child: Text('Per Meter')),
                  DropdownMenuItem(value: 'yard', child: Text('Per Yard')),
                ],
                onChanged: (value) => setState(() => _pricingUnit = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Additional information',
                ),
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isCreating ? null : _createMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA16438),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Material',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// ==================== HARDWARE MATERIAL ====================
class CreateHardwareMaterialPage extends StatefulWidget {
  const CreateHardwareMaterialPage({super.key});

  @override
  State<CreateHardwareMaterialPage> createState() =>
      _CreateHardwareMaterialPageState();
}

class _CreateHardwareMaterialPageState
    extends State<CreateHardwareMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _pricingUnit = 'piece';
  String? _imagePath;
  Map<String, dynamic>? _selectedCatalogMaterial;
  bool _useCatalog = true;
  bool isCreating = false;

  Future<void> _createMaterial() async {
    if (_useCatalog && _selectedCatalogMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supported catalog material')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isCreating = true);

    final baseRequest = _useCatalog
        ? buildCatalogMaterialCreateFields(_selectedCatalogMaterial!)
        : <String, dynamic>{
            'useCatalog': false,
            'name': _nameController.text.trim(),
            'category': _categoryController.text.trim(),
            if (_subCategoryController.text.trim().isNotEmpty)
              'subCategory': _subCategoryController.text.trim(),
            if (_sizeController.text.trim().isNotEmpty)
              'size': _sizeController.text.trim(),
            if (_unitController.text.trim().isNotEmpty)
              'unit': _unitController.text.trim(),
            if (_colorController.text.trim().isNotEmpty)
              'color': _colorController.text.trim(),
          };

    final request = {
      ...baseRequest,
      if (_imagePath != null) 'imagePath': _imagePath,
      'pricePerUnit': double.parse(_priceController.text),
      'pricingUnit': _pricingUnit,
      if (_notesController.text.isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    final result = await _materialService.createMaterial(request);

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material submitted for review')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to create material'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickCatalogMaterial() async {
    final selected = await pickSupportedCatalogMaterial(
      context: context,
      materialService: _materialService,
      title: 'Select Hardware Catalog Material',
    );
    if (selected == null) return;
    setState(() {
      _selectedCatalogMaterial = selected;
      _nameController.text = catalogMaterialDisplayName(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: const Text(
          "Create Hardware Material",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomImgBg(
              placeholderText: 'Add Material Image (Optional)',
              selectedImagePath: _imagePath,
              onImageSelected: (image) {
                setState(() => _imagePath = image?.path);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF607D8B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF607D8B).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.construction, color: const Color(0xFF607D8B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hardware includes handles, hinges, screws, nails, and fittings.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF607D8B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard([
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Supported Catalog (Recommended)'),
                subtitle: const Text(
                  'Turn this off to enter a custom material name (non-catalog).',
                ),
                value: _useCatalog,
                onChanged: (v) {
                  setState(() {
                    _useCatalog = v;
                    if (!_useCatalog) {
                      _selectedCatalogMaterial = null;
                    } else if (_selectedCatalogMaterial != null) {
                      _nameController.text = catalogMaterialDisplayName(
                        _selectedCatalogMaterial!,
                      );
                    }
                  });
                },
              ),
              TextFormField(
                controller: _nameController,
                readOnly: _useCatalog,
                decoration: const InputDecoration(
                  labelText: 'Hardware Name *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Handle 1, Edge Tape, Nails',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              if (!_useCatalog) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Angle_bracket, Handle, Edge_tape',
                  ),
                  validator: (value) {
                    if (_useCatalog) return null;
                    return (value?.trim().isEmpty ?? true) ? 'Required' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Sub Category (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Aluminium, Iron',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sizeController,
                        decoration: const InputDecoration(
                          labelText: 'Size (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 8',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Piece, Pack',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Gold, Black',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _useCatalog ? _pickCatalogMaterial : null,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  _selectedCatalogMaterial == null
                      ? 'Select From Supported Catalog'
                      : 'Change Catalog Material',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                  prefixText: '₦',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _pricingUnit,
                decoration: const InputDecoration(
                  labelText: 'Pricing Unit *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'piece', child: Text('Per Piece')),
                  DropdownMenuItem(value: 'pound', child: Text('Per Pound')),
                  DropdownMenuItem(value: 'bag', child: Text('Per Bag')),
                  DropdownMenuItem(value: 'meter', child: Text('Per Meter')),
                  DropdownMenuItem(value: 'set', child: Text('Per Set')),
                ],
                onChanged: (value) => setState(() => _pricingUnit = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., "Nail is per pound weight"',
                ),
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isCreating ? null : _createMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA16438),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Material',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _sizeController.dispose();
    _unitController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// ==================== OTHER MATERIAL ====================
class CreateOtherMaterialPage extends StatefulWidget {
  const CreateOtherMaterialPage({super.key});

  @override
  State<CreateOtherMaterialPage> createState() =>
      _CreateOtherMaterialPageState();
}

class _CreateOtherMaterialPageState extends State<CreateOtherMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _pricingUnit = 'liter';
  String? _imagePath;
  Map<String, dynamic>? _selectedCatalogMaterial;
  bool _useCatalog = true;
  bool isCreating = false;

  Future<void> _createMaterial() async {
    if (_useCatalog && _selectedCatalogMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supported catalog material')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isCreating = true);

    final baseRequest = _useCatalog
        ? buildCatalogMaterialCreateFields(_selectedCatalogMaterial!)
        : <String, dynamic>{
            'useCatalog': false,
            'name': _nameController.text.trim(),
            'category': _categoryController.text.trim(),
            if (_subCategoryController.text.trim().isNotEmpty)
              'subCategory': _subCategoryController.text.trim(),
            if (_sizeController.text.trim().isNotEmpty)
              'size': _sizeController.text.trim(),
            if (_unitController.text.trim().isNotEmpty)
              'unit': _unitController.text.trim(),
            if (_colorController.text.trim().isNotEmpty)
              'color': _colorController.text.trim(),
          };

    final request = {
      ...baseRequest,
      if (_imagePath != null) 'imagePath': _imagePath,
      'pricePerUnit': double.parse(_priceController.text),
      'pricingUnit': _pricingUnit,
      if (_notesController.text.isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    final result = await _materialService.createMaterial(request);

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material submitted for review')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to create material'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickCatalogMaterial() async {
    final selected = await pickSupportedCatalogMaterial(
      context: context,
      materialService: _materialService,
      title: 'Select Catalog Material',
    );
    if (selected == null) return;
    setState(() {
      _selectedCatalogMaterial = selected;
      _nameController.text = catalogMaterialDisplayName(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: const Text(
          "Create Other Material",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomImgBg(
              placeholderText: 'Add Material Image (Optional)',
              selectedImagePath: _imagePath,
              onImageSelected: (image) {
                setState(() => _imagePath = image?.path);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF9E9E9E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF9E9E9E).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.more_horiz, color: const Color(0xFF9E9E9E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Other materials include paint, glue, varnish, and miscellaneous items.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard([
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Supported Catalog (Recommended)'),
                subtitle: const Text(
                  'Turn this off to enter a custom material name (non-catalog).',
                ),
                value: _useCatalog,
                onChanged: (v) {
                  setState(() {
                    _useCatalog = v;
                    if (!_useCatalog) {
                      _selectedCatalogMaterial = null;
                    } else if (_selectedCatalogMaterial != null) {
                      _nameController.text = catalogMaterialDisplayName(
                        _selectedCatalogMaterial!,
                      );
                    }
                  });
                },
              ),
              TextFormField(
                controller: _nameController,
                readOnly: _useCatalog,
                decoration: const InputDecoration(
                  labelText: 'Material Name *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Paint, Glue, Varnish',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              if (!_useCatalog) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Paint, Glue, Varnish',
                  ),
                  validator: (value) {
                    if (_useCatalog) return null;
                    return (value?.trim().isEmpty ?? true) ? 'Required' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Sub Category (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sizeController,
                        decoration: const InputDecoration(
                          labelText: 'Size (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _useCatalog ? _pickCatalogMaterial : null,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  _selectedCatalogMaterial == null
                      ? 'Select From Supported Catalog'
                      : 'Change Catalog Material',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                  prefixText: '₦',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _pricingUnit,
                decoration: const InputDecoration(
                  labelText: 'Pricing Unit *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'liter', child: Text('Per Liter')),
                  DropdownMenuItem(value: 'piece', child: Text('Per Piece')),
                  DropdownMenuItem(value: 'kg', child: Text('Per Kilogram')),
                  DropdownMenuItem(value: 'gallon', child: Text('Per Gallon')),
                ],
                onChanged: (value) => setState(() => _pricingUnit = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Additional information',
                ),
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isCreating ? null : _createMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA16438),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Material',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _sizeController.dispose();
    _unitController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
