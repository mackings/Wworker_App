import 'package:flutter/material.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/MaterialUpload/Api/SmaterialService.dart';

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
  String? _imagePath;
  bool isCreating = false;

  // Foam variants (thickness + density combinations)
  List<FoamVariant> foamVariants = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isCreating = true);

    final request = {
      'name': _nameController.text.trim(),
      'category': 'FOAM',
      if (_imagePath != null) 'imagePath': _imagePath,
      'standardWidth': double.parse(_standardWidthController.text),
      'standardLength': double.parse(_standardLengthController.text),
      'standardUnit': _standardUnit,
      'pricingUnit': 'sqm',
      'wasteThreshold': double.parse(_wasteThresholdController.text),
      if (_pricePerSqmController.text.isNotEmpty)
        'pricePerSqm': double.parse(_pricePerSqmController.text),
      if (foamVariants.isNotEmpty)
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                          isEditing ? 'Edit Foam Variant' : 'Add Foam Variant',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF302E2E),
                          ),
                        ),
                        if (isEditing)
                          TextButton(
                            onPressed: () {
                              setState(() => foamVariants.removeAt(editIndex));
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: thicknessController,
                            decoration: InputDecoration(
                              labelText: 'Thickness *',
                              filled: true,
                              fillColor: const Color(0xFFF7F5F2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: thicknessUnit,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'mm', child: Text('mm')),
                            DropdownMenuItem(value: 'cm', child: Text('cm')),
                            DropdownMenuItem(value: 'inches', child: Text('in')),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => thicknessUnit = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: densityController,
                      decoration: InputDecoration(
                        labelText: 'Density *',
                        hintText: 'e.g., lemon, ordinary, grey',
                        filled: true,
                        fillColor: const Color(0xFFF7F5F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widthController,
                            decoration: InputDecoration(
                              labelText: 'Width *',
                              filled: true,
                              fillColor: const Color(0xFFF7F5F2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lengthController,
                            decoration: InputDecoration(
                              labelText: 'Length *',
                              filled: true,
                              fillColor: const Color(0xFFF7F5F2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: dimensionUnit,
                      decoration: InputDecoration(
                        labelText: 'Dimension Unit',
                        filled: true,
                        fillColor: const Color(0xFFF7F5F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mm', child: Text('mm')),
                        DropdownMenuItem(value: 'cm', child: Text('cm')),
                        DropdownMenuItem(value: 'inches', child: Text('inches')),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => dimensionUnit = value!),
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
                          if (thicknessController.text.isEmpty ||
                              densityController.text.isEmpty ||
                              widthController.text.isEmpty ||
                              lengthController.text.isEmpty) {
                            return;
                          }

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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA16438),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isEditing ? 'Save Changes' : 'Add Variant'),
                      ),
                    ),
                  ],
                ),
              ),
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
            CustomImgBg(
              placeholderText: 'Add Material Image (Optional)',
              onImageSelected: (image) {
                setState(() => _imagePath = image?.path);
              },
            ),
            const SizedBox(height: 16),
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

            _buildSectionCard(
              'Material Settings',
              [
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
                'Foam Variants',
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
