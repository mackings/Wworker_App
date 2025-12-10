import 'package:flutter/material.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';

class CreateMarbleMaterialPage extends StatefulWidget {
  const CreateMarbleMaterialPage({super.key});

  @override
  State<CreateMarbleMaterialPage> createState() => _CreateMarbleMaterialPageState();
}

class _CreateMarbleMaterialPageState extends State<CreateMarbleMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  final TextEditingController _nameController = TextEditingController(text: 'Marble');
  final TextEditingController _standardWidthController = TextEditingController();
  final TextEditingController _standardLengthController = TextEditingController();
  final TextEditingController _pricePerSqmController = TextEditingController();
  final TextEditingController _wasteThresholdController = TextEditingController(text: '0.75');

  String _standardUnit = 'inches';
  bool isCreating = false;

  // Size variants (different sheet sizes)
  List<SizeVariant> sizeVariants = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate common marble sizes
    sizeVariants = [
      SizeVariant(
        name: 'Full Sheet Lemon',
        width: 60,
        length: 81,
        unit: 'inches',
        pricePerUnit: null,
      ),
      SizeVariant(
        name: 'Full Sheet Ordinary',
        width: 60,
        length: 72,
        unit: 'inches',
        pricePerUnit: null,
      ),
    ];
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    final variantsWithPrices = sizeVariants.where((v) => v.pricePerUnit != null).toList();
    if (variantsWithPrices.isEmpty && _pricePerSqmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a base price or at least one variant price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isCreating = true);

    final request = {
      'name': _nameController.text.trim(),
      'category': 'MARBLE',
      'standardWidth': double.parse(_standardWidthController.text),
      'standardLength': double.parse(_standardLengthController.text),
      'standardUnit': _standardUnit,
      'pricePerSqm': _pricePerSqmController.text.isNotEmpty 
          ? double.parse(_pricePerSqmController.text) 
          : 0,
      'pricingUnit': 'sqm',
      'wasteThreshold': double.parse(_wasteThresholdController.text),
      'sizeVariants': sizeVariants.map((v) => {
        'name': v.name,
        'width': v.width,
        'length': v.length,
        'unit': v.unit,
        if (v.pricePerUnit != null) 'pricePerUnit': v.pricePerUnit,
      }).toList(),
    };

    final result = await _materialService.createMaterial(request);

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marble material created successfully')),
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

  void _addSizeVariant() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final widthController = TextEditingController();
        final lengthController = TextEditingController();
        final priceController = TextEditingController();
        String unit = 'inches';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Size Variant'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Variant Name *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Full Sheet Premium',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widthController,
                            decoration: const InputDecoration(
                              labelText: 'Width *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lengthController,
                            decoration: const InputDecoration(
                              labelText: 'Length *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mm', child: Text('mm')),
                        DropdownMenuItem(value: 'cm', child: Text('cm')),
                        DropdownMenuItem(value: 'inches', child: Text('inches')),
                      ],
                      onChanged: (value) => setDialogState(() => unit = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per Unit',
                        border: OutlineInputBorder(),
                        prefixText: '₦',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        widthController.text.isNotEmpty &&
                        lengthController.text.isNotEmpty) {
                      setState(() {
                        sizeVariants.add(
                          SizeVariant(
                            name: nameController.text.trim(),
                            width: double.parse(widthController.text),
                            length: double.parse(lengthController.text),
                            unit: unit,
                            pricePerUnit: priceController.text.isNotEmpty
                                ? double.tryParse(priceController.text)
                                : null,
                          ),
                        );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Create Marble Material",
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7B68EE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7B68EE).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.landscape, color: const Color(0xFF7B68EE)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Marble materials come in different sheet sizes and qualities.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF7B68EE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard('Basic Information', [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ]),
            const SizedBox(height: 16),

            _buildSectionCard('Standard Sheet Size', [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _standardWidthController,
                      decoration: const InputDecoration(
                        labelText: 'Width *',
                        border: OutlineInputBorder(),
                        hintText: '60',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _standardLengthController,
                      decoration: const InputDecoration(
                        labelText: 'Length *',
                        border: OutlineInputBorder(),
                        hintText: '81',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                  DropdownMenuItem(value: 'mm', child: Text('Millimeters')),
                  DropdownMenuItem(value: 'cm', child: Text('Centimeters')),
                  DropdownMenuItem(value: 'm', child: Text('Meters')),
                  DropdownMenuItem(value: 'inches', child: Text('Inches')),
                ],
                onChanged: (value) => setState(() => _standardUnit = value!),
              ),
            ]),
            const SizedBox(height: 16),

            _buildSectionCard('Base Pricing (Optional)', [
              TextFormField(
                controller: _pricePerSqmController,
                decoration: const InputDecoration(
                  labelText: 'Base Price per m²',
                  border: OutlineInputBorder(),
                  prefixText: '₦',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wasteThresholdController,
                decoration: const InputDecoration(
                  labelText: 'Waste Threshold',
                  border: OutlineInputBorder(),
                  hintText: '0.75 = 75%',
                ),
                keyboardType: TextInputType.number,
              ),
            ]),
            const SizedBox(height: 16),

            _buildSizeVariantsSection(),
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
                        'Create Marble Material',
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

  Widget _buildSizeVariantsSection() {
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
                'Size Variants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF302E2E),
                ),
              ),
              TextButton.icon(
                onPressed: _addSizeVariant,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sizeVariants.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No size variants added',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...sizeVariants.map((variant) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Size: ${variant.width} × ${variant.length} ${variant.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (variant.pricePerUnit != null)
                      Text(
                        '₦${_formatNumber(variant.pricePerUnit!)} per unit',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA16438),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
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

class SizeVariant {
  final String name;
  final double width;
  final double length;
  final String unit;
  final double? pricePerUnit;

  SizeVariant({
    required this.name,
    required this.width,
    required this.length,
    required this.unit,
    this.pricePerUnit,
  });
}