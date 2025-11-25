import 'package:flutter/material.dart';
import 'package:wworker/App/Settings/Api/SmaterialService.dart';
import 'package:wworker/App/Settings/Model/SMaterialModel.dart';

class CreateMaterialPage extends StatefulWidget {
  const CreateMaterialPage({super.key});

  @override
  State<CreateMaterialPage> createState() => _CreateMaterialPageState();
}

class _CreateMaterialPageState extends State<CreateMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _standardWidthController = TextEditingController();
  final TextEditingController _standardLengthController = TextEditingController();
  final TextEditingController _standardUnitController = TextEditingController();
  final TextEditingController _pricePerSqmController = TextEditingController();
  final TextEditingController _wasteThresholdController = TextEditingController(text: '0.75');

  // Lists for dynamic fields
  List<MaterialSize> sizes = [];
  List<FoamDensity> foamDensities = [];
  List<FoamThickness> foamThicknesses = [];

  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    // Set default standard unit
    _standardUnitController.text = 'm';
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isCreating = true);

    final request = CreateMaterialRequest(
      name: _nameController.text.trim(),
      unit: _unitController.text.trim(),
      standardWidth: double.parse(_standardWidthController.text),
      standardLength: double.parse(_standardLengthController.text),
      standardUnit: _standardUnitController.text.trim(),
      pricePerSqm: double.parse(_pricePerSqmController.text),
      sizes: sizes.isNotEmpty ? sizes : null,
      foamDensities: foamDensities.isNotEmpty ? foamDensities : null,
      foamThicknesses: foamThicknesses.isNotEmpty ? foamThicknesses : null,
      wasteThreshold: double.tryParse(_wasteThresholdController.text),
    );

    final result = await _materialService.createMaterial(request);

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material created successfully')),
      );
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

  void _addSize() {
    showDialog(
      context: context,
      builder: (context) {
        final widthController = TextEditingController();
        final lengthController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: widthController,
                decoration: const InputDecoration(
                  labelText: 'Width',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lengthController,
                decoration: const InputDecoration(
                  labelText: 'Length',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (widthController.text.isNotEmpty &&
                    lengthController.text.isNotEmpty) {
                  setState(() {
                    sizes.add(
                      MaterialSize(
                        width: double.parse(widthController.text),
                        length: double.parse(lengthController.text),
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
  }

  void _addFoamDensity() {
    showDialog(
      context: context,
      builder: (context) {
        final densityController = TextEditingController();
        final unitController = TextEditingController(text: 'kg/m³');

        return AlertDialog(
          title: const Text('Add Foam Density'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: densityController,
                decoration: const InputDecoration(
                  labelText: 'Density',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (densityController.text.isNotEmpty) {
                  setState(() {
                    foamDensities.add(
                      FoamDensity(
                        density: double.parse(densityController.text),
                        unit: unitController.text.trim(),
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
  }

  void _addFoamThickness() {
    showDialog(
      context: context,
      builder: (context) {
        final thicknessController = TextEditingController();
        final unitController = TextEditingController(text: 'mm');

        return AlertDialog(
          title: const Text('Add Foam Thickness'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: thicknessController,
                decoration: const InputDecoration(
                  labelText: 'Thickness',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (thicknessController.text.isNotEmpty) {
                  setState(() {
                    foamThicknesses.add(
                      FoamThickness(
                        thickness: double.parse(thicknessController.text),
                        unit: unitController.text.trim(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Create Material",
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
            // Basic Information
            _buildSectionCard(
              'Basic Information',
              [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Material Name *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Wood, Foam',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter material name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., sqm, m',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter unit';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Standard Dimensions
            _buildSectionCard(
              'Standard Dimensions',
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _standardUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Standard Unit *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., m, cm',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter standard unit';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pricing
            _buildSectionCard(
              'Pricing',
              [
                TextFormField(
                  controller: _pricePerSqmController,
                  decoration: const InputDecoration(
                    labelText: 'Price per sqm *',
                    border: OutlineInputBorder(),
                    prefixText: '₦',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _wasteThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Waste Threshold',
                    border: OutlineInputBorder(),
                    hintText: '0.75 (75%)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sizes
            _buildListSectionCard(
              'Available Sizes',
              sizes.isEmpty
                  ? 'No sizes added'
                  : sizes
                      .map((s) => '${s.width} x ${s.length}')
                      .join(', '),
              _addSize,
              () => setState(() => sizes.clear()),
            ),
            const SizedBox(height: 16),

            // Foam Densities
            _buildListSectionCard(
              'Foam Densities',
              foamDensities.isEmpty
                  ? 'No densities added'
                  : foamDensities
                      .map((d) => '${d.density} ${d.unit}')
                      .join(', '),
              _addFoamDensity,
              () => setState(() => foamDensities.clear()),
            ),
            const SizedBox(height: 16),

            // Foam Thicknesses
            _buildListSectionCard(
              'Foam Thicknesses',
              foamThicknesses.isEmpty
                  ? 'No thicknesses added'
                  : foamThicknesses
                      .map((t) => '${t.thickness} ${t.unit}')
                      .join(', '),
              _addFoamThickness,
              () => setState(() => foamThicknesses.clear()),
            ),
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
                        'Create Material',
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

  Widget _buildListSectionCard(
    String title,
    String content,
    VoidCallback onAdd,
    VoidCallback onClear,
  ) {
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF302E2E),
                ),
              ),
              Row(
                children: [
                  if (content != 'No sizes added' &&
                      content != 'No densities added' &&
                      content != 'No thicknesses added')
                    TextButton(
                      onPressed: onClear,
                      child: const Text('Clear'),
                    ),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: content.startsWith('No') ? Colors.grey : const Color(0xFF302E2E),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _standardWidthController.dispose();
    _standardLengthController.dispose();
    _standardUnitController.dispose();
    _pricePerSqmController.dispose();
    _wasteThresholdController.dispose();
    super.dispose();
  }
}