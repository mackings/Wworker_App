import 'package:flutter/material.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';

class CreateWoodMaterialPage extends StatefulWidget {
  const CreateWoodMaterialPage({super.key});

  @override
  State<CreateWoodMaterialPage> createState() => _CreateWoodMaterialPageState();
}

class _CreateWoodMaterialPageState extends State<CreateWoodMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  // Controllers
  final TextEditingController _nameController = TextEditingController(text: 'Wood');
  final TextEditingController _standardWidthController = TextEditingController();
  final TextEditingController _standardLengthController = TextEditingController();
  final TextEditingController _pricePerSqmController = TextEditingController();
  final TextEditingController _wasteThresholdController = TextEditingController(text: '0.75');

  String _standardUnit = 'inches';
  String _thicknessUnit = 'inches';
  String? _imagePath;
  bool isCreating = false;

  // Wood types and thicknesses
  List<WoodType> woodTypes = [];
  List<ThicknessOption> commonThicknesses = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isCreating = true);

    final request = {
      'name': _nameController.text.trim(),
      'category': 'WOOD',
      if (_imagePath != null) 'imagePath': _imagePath,
      'standardWidth': double.parse(_standardWidthController.text),
      'standardLength': double.parse(_standardLengthController.text),
      'standardUnit': _standardUnit,
      'pricingUnit': 'sqm',
      'wasteThreshold': double.parse(_wasteThresholdController.text),
      if (_pricePerSqmController.text.isNotEmpty)
        'pricePerSqm': double.parse(_pricePerSqmController.text),
      if (woodTypes.isNotEmpty)
        'types': woodTypes.map((t) => {
              'name': t.name,
              if (t.pricePerSqm != null) 'pricePerSqm': t.pricePerSqm,
            }).toList(),
      if (commonThicknesses.isNotEmpty)
        'commonThicknesses': commonThicknesses.map((t) => {
              'thickness': t.thickness,
              'unit': _thicknessUnit,
            }).toList(),
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

  void _addThickness() {
    showDialog(
      context: context,
      builder: (context) {
        final thicknessController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Thickness'),
          content: TextField(
            controller: thicknessController,
            decoration: InputDecoration(
              labelText: 'Thickness *',
              border: const OutlineInputBorder(),
              hintText: _thicknessUnit == 'inches' ? 'e.g., 0.75' : 'e.g., 18',
              suffix: Text(_thicknessUnit),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(thicknessController.text);
                if (value != null) {
                  setState(() {
                    commonThicknesses.add(ThicknessOption(thickness: value));
                    commonThicknesses.sort((a, b) => a.thickness.compareTo(b.thickness));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA16438),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addWoodType() {
    _openWoodTypeSheet();
  }

  void _editWoodType(int index) {
    _openWoodTypeSheet(editIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Create Wood Material",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomImgBg(
              placeholderText: 'Add Material Image (Optional)',
              onImageSelected: (image) {
                setState(() => _imagePath = image?.path);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B4513).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.forest, color: const Color(0xFF8B4513)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Wood materials are priced per square meter. Add different wood types and available thicknesses.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF8B4513),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              'Basic Information',
              [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Material Name *',
                    border: OutlineInputBorder(),
                    hintText: 'Wood',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              'Standard Sheet Size',
              [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _standardWidthController,
                        decoration: const InputDecoration(
                          labelText: 'Width *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _standardLengthController,
                        decoration: const InputDecoration(
                          labelText: 'Length *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _standardUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mm', child: Text('Millimeters (mm)')),
                    DropdownMenuItem(value: 'cm', child: Text('Centimeters (cm)')),
                    DropdownMenuItem(value: 'm', child: Text('Meters (m)')),
                    DropdownMenuItem(value: 'inches', child: Text('Inches (in)')),
                    DropdownMenuItem(value: 'ft', child: Text('Feet (ft)')),
                  ],
                  onChanged: (value) => setState(() => _standardUnit = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildThicknessSection(),
            const SizedBox(height: 16),

            _buildSectionCard(
              'Material Settings',
              [
                TextFormField(
                  controller: _wasteThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Waste Threshold',
                    border: OutlineInputBorder(),
                    hintText: '0.75 = 75%',
                    helperText: 'Used to calculate material waste',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildWoodTypesSection(),
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

  Widget _buildThicknessSection() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Thicknesses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF302E2E),
                ),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _thicknessUnit,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'mm', child: Text('mm')),
                      DropdownMenuItem(value: 'inches', child: Text('inches')),
                    ],
                    onChanged: (value) => setState(() => _thicknessUnit = value!),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _addThickness,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (commonThicknesses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No thicknesses added',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: commonThicknesses.asMap().entries.map((entry) {
                final index = entry.key;
                final thickness = entry.value;
                return Chip(
                  label: Text('${thickness.thickness}$_thicknessUnit'),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => commonThicknesses.removeAt(index));
                  },
                  backgroundColor: const Color(0xFFA16438).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Color(0xFFA16438),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
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
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF302E2E),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildWoodTypesSection() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wood Types',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF302E2E),
                ),
              ),
              TextButton.icon(
                onPressed: _addWoodType,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Type'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (woodTypes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No wood types added',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...woodTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              return GestureDetector(
                onTap: () => _editWoodType(index),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (type.pricePerSqm != null)
                              Text(
                                '₦${_formatNumber(type.pricePerSqm!)} per m²',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFA16438),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              const Text(
                                'No price set',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Future<void> _openWoodTypeSheet({int? editIndex}) async {
    final isEditing = editIndex != null;
    final existing = isEditing ? woodTypes[editIndex!] : null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController = TextEditingController(
      text: existing?.pricePerSqm?.toString() ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Wood Type' : 'Add Wood Type',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF302E2E),
                      ),
                    ),
                    if (isEditing)
                      TextButton(
                        onPressed: () {
                          setState(() => woodTypes.removeAt(editIndex!));
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Type Name *',
                    filled: true,
                    fillColor: const Color(0xFFF7F5F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price per m² (optional)',
                    prefixText: '₦ ',
                    filled: true,
                    fillColor: const Color(0xFFF7F5F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;
                      setState(() {
                        final updated = WoodType(
                          name: nameController.text.trim(),
                          pricePerSqm: priceController.text.isNotEmpty
                              ? double.tryParse(priceController.text)
                              : null,
                        );
                        if (isEditing) {
                          woodTypes[editIndex!] = updated;
                        } else {
                          woodTypes.add(updated);
                        }
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA16438),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Add Type'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _standardWidthController.dispose();
    _standardLengthController.dispose();
    _pricePerSqmController.dispose();
    _wasteThresholdController.dispose();
    super.dispose();
  }
}

class WoodType {
  final String name;
  final double? pricePerSqm;

  WoodType({required this.name, this.pricePerSqm});
}

class ThicknessOption {
  final double thickness;

  ThicknessOption({required this.thickness});
}
