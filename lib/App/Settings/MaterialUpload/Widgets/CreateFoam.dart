import 'package:flutter/material.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';

import 'package:flutter/material.dart';

class CreateFoamMaterialPage extends StatefulWidget {
  const CreateFoamMaterialPage({super.key});

  @override
  State<CreateFoamMaterialPage> createState() => _CreateFoamMaterialPageState();
}

class _CreateFoamMaterialPageState extends State<CreateFoamMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  // Controllers
  final TextEditingController _nameController = TextEditingController(text: 'Foam');
  final TextEditingController _standardWidthController = TextEditingController();
  final TextEditingController _standardLengthController = TextEditingController();
  final TextEditingController _pricePerSqmController = TextEditingController();
  final TextEditingController _wasteThresholdController = TextEditingController(text: '0.75');

  String _standardUnit = 'inches';
  bool isCreating = false;

  // Foam variants (thickness + density combinations)
  List<FoamVariant> foamVariants = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate common foam variants
    foamVariants = [
      FoamVariant(
        thickness: 0.5,
        thicknessUnit: 'inches',
        density: 'ordinary',
        width: 21,
        length: 60,
        dimensionUnit: 'inches',
        pricePerSqm: null,
      ),
      FoamVariant(
        thickness: 0.5,
        thicknessUnit: 'inches',
        density: 'lemon',
        width: 21,
        length: 60,
        dimensionUnit: 'inches',
        pricePerSqm: null,
      ),
      FoamVariant(
        thickness: 1,
        thicknessUnit: 'inches',
        density: 'ordinary',
        width: 48,
        length: 96,
        dimensionUnit: 'inches',
        pricePerSqm: null,
      ),
      FoamVariant(
        thickness: 1,
        thicknessUnit: 'inches',
        density: 'lemon',
        width: 48,
        length: 96,
        dimensionUnit: 'inches',
        pricePerSqm: null,
      ),
      FoamVariant(
        thickness: 2,
        thicknessUnit: 'inches',
        density: 'ordinary',
        width: 48,
        length: 96,
        dimensionUnit: 'inches',
        pricePerSqm: null,
      ),
      FoamVariant(
        thickness: 2,
        thicknessUnit: 'inches',
        density: 'lemon',
        width: 48,
        length: 96,
        dimensionUnit: 'inches',
        pricePerSqm: null,
      ),
    ];
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one variant has a price
    final variantsWithPrices = foamVariants.where((v) => v.pricePerSqm != null).toList();
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
      'category': 'FOAM',
      'standardWidth': double.parse(_standardWidthController.text),
      'standardLength': double.parse(_standardLengthController.text),
      'standardUnit': _standardUnit,
      'pricePerSqm': _pricePerSqmController.text.isNotEmpty 
          ? double.parse(_pricePerSqmController.text) 
          : 0,
      'pricingUnit': 'sqm',
      'wasteThreshold': double.parse(_wasteThresholdController.text),
      'foamVariants': foamVariants.map((v) => {
        'thickness': v.thickness,
        'thicknessUnit': v.thicknessUnit,
        'density': v.density,
        'width': v.width,
        'length': v.length,
        'dimensionUnit': v.dimensionUnit,
        if (v.pricePerSqm != null) 'pricePerSqm': v.pricePerSqm,
      }).toList(),
    };

    final result = await _materialService.createMaterial(request);

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foam material created successfully')),
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

  void _showVariantDialog({int? editIndex}) {
    final isEditing = editIndex != null;
    final variant = isEditing ? foamVariants[editIndex] : null;

    final thicknessController = TextEditingController(
      text: variant?.thickness.toString() ?? '',
    );
    final densityController = TextEditingController(
      text: variant?.density ?? '',
    );
    final widthController = TextEditingController(
      text: variant?.width.toString() ?? '',
    );
    final lengthController = TextEditingController(
      text: variant?.length.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: variant?.pricePerSqm?.toString() ?? '',
    );
    
    String thicknessUnit = variant?.thicknessUnit ?? 'inches';
    String dimensionUnit = variant?.dimensionUnit ?? 'inches';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Foam Variant' : 'Add Foam Variant'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: thicknessController,
                            decoration: const InputDecoration(
                              labelText: 'Thickness *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: thicknessUnit,
                          items: const [
                            DropdownMenuItem(value: 'mm', child: Text('mm')),
                            DropdownMenuItem(value: 'cm', child: Text('cm')),
                            DropdownMenuItem(value: 'inches', child: Text('in')),
                          ],
                          onChanged: (value) => setDialogState(() => thicknessUnit = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: densityController,
                      decoration: const InputDecoration(
                        labelText: 'Density *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., lemon, ordinary, grey',
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
                      value: dimensionUnit,
                      decoration: const InputDecoration(
                        labelText: 'Dimension Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mm', child: Text('mm')),
                        DropdownMenuItem(value: 'cm', child: Text('cm')),
                        DropdownMenuItem(value: 'inches', child: Text('inches')),
                      ],
                      onChanged: (value) => setDialogState(() => dimensionUnit = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per m²',
                        border: OutlineInputBorder(),
                        prefixText: '₦',
                        hintText: 'Optional',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => foamVariants.removeAt(editIndex));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (thicknessController.text.isNotEmpty &&
                        densityController.text.isNotEmpty &&
                        widthController.text.isNotEmpty &&
                        lengthController.text.isNotEmpty) {
                      
                      final newVariant = FoamVariant(
                        thickness: double.parse(thicknessController.text),
                        thicknessUnit: thicknessUnit,
                        density: densityController.text.trim(),
                        width: double.parse(widthController.text),
                        length: double.parse(lengthController.text),
                        dimensionUnit: dimensionUnit,
                        pricePerSqm: priceController.text.isNotEmpty
                            ? double.tryParse(priceController.text)
                            : null,
                      );

                      setState(() {
                        if (isEditing) {
                          foamVariants[editIndex] = newVariant;
                        } else {
                          foamVariants.add(newVariant);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA16438),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _quickSetPrice(int index) {
    final variant = foamVariants[index];
    final priceController = TextEditingController(
      text: variant.pricePerSqm?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Price for ${variant.thickness}" ${variant.density}',
          style: const TextStyle(fontSize: 16),
        ),
        content: TextField(
          controller: priceController,
          decoration: const InputDecoration(
            labelText: 'Price per m²',
            border: OutlineInputBorder(),
            prefixText: '₦',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                foamVariants[index] = FoamVariant(
                  thickness: variant.thickness,
                  thicknessUnit: variant.thicknessUnit,
                  density: variant.density,
                  width: variant.width,
                  length: variant.length,
                  dimensionUnit: variant.dimensionUnit,
                  pricePerSqm: priceController.text.isNotEmpty
                      ? double.tryParse(priceController.text)
                      : null,
                );
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA16438),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
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
          "Create Foam Material",
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
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.airlines, color: const Color(0xFF4A90E2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Foam is priced based on thickness and density combinations. Tap a variant to set its price.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF4A90E2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Basic Information
            _buildSectionCard(
              'Basic Information',
              [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Material Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Standard Dimensions (most common foam size)
            _buildSectionCard(
              'Standard Sheet Size (Base)',
              [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _standardWidthController,
                        decoration: const InputDecoration(
                          labelText: 'Width *',
                          border: OutlineInputBorder(),
                          hintText: '48',
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
                          hintText: '96',
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
                    DropdownMenuItem(value: 'mm', child: Text('Millimeters')),
                    DropdownMenuItem(value: 'cm', child: Text('Centimeters')),
                    DropdownMenuItem(value: 'm', child: Text('Meters')),
                    DropdownMenuItem(value: 'inches', child: Text('Inches')),
                  ],
                  onChanged: (value) => setState(() => _standardUnit = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Base Pricing
            _buildSectionCard(
              'Base Pricing (Optional)',
              [
                TextFormField(
                  controller: _pricePerSqmController,
                  decoration: const InputDecoration(
                    labelText: 'Base Price per m²',
                    border: OutlineInputBorder(),
                    prefixText: '₦',
                    hintText: 'Leave empty if variants have different prices',
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
              ],
            ),
            const SizedBox(height: 16),

            // Foam Variants
            _buildFoamVariantsSection(),
            const SizedBox(height: 32),

            // Create Button
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
                        'Create Foam Material',
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

  Widget _buildFoamVariantsSection() {
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
                'Foam Variants (Thickness + Density)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF302E2E),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showVariantDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (foamVariants.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No foam variants added',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...foamVariants.asMap().entries.map((entry) {
              final index = entry.key;
              final variant = entry.value;
              final hasPrice = variant.pricePerSqm != null;
              
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: hasPrice ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasPrice ? Colors.green[200]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${variant.thickness}${variant.thicknessUnit} - ${variant.density}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasPrice)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRICED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${variant.width} × ${variant.length} ${variant.dimensionUnit}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasPrice)
                            Text(
                              '₦${_formatNumber(variant.pricePerSqm!)} per m²',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFA16438),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            const Text(
                              'Tap to set price',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.payments,
                            color: hasPrice ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          onPressed: () => _quickSetPrice(index),
                          tooltip: 'Set Price',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => _showVariantDialog(editIndex: index),
                          tooltip: 'Edit Variant',
                        ),
                      ],
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

class FoamVariant {
  final double thickness;
  final String thicknessUnit;
  final String density;
  final double width;
  final double length;
  final String dimensionUnit;
  final double? pricePerSqm;

  FoamVariant({
    required this.thickness,
    required this.thicknessUnit,
    required this.density,
    required this.width,
    required this.length,
    required this.dimensionUnit,
    this.pricePerSqm,
  });
}