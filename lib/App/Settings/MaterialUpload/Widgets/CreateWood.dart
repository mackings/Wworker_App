import 'package:flutter/material.dart';
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
  bool isCreating = false;

  // Wood types with prices
  List<WoodType> woodTypes = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate common wood types (user can modify)
    woodTypes = [
      WoodType(name: 'Iroko', pricePerSqm: null),
      WoodType(name: 'Mahogany', pricePerSqm: null),
      WoodType(name: 'Melina', pricePerSqm: null),
      WoodType(name: 'Eku', pricePerSqm: null),
      WoodType(name: 'Rough', pricePerSqm: null),
      WoodType(name: 'Thick', pricePerSqm: null),
      WoodType(name: 'Ordinary', pricePerSqm: null),
    ];
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one type has a price
    final typesWithPrices = woodTypes.where((t) => t.pricePerSqm != null).toList();
    if (typesWithPrices.isEmpty && _pricePerSqmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a base price or at least one type price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isCreating = true);

    final request = {
      'name': _nameController.text.trim(),
      'category': 'WOOD',
      'standardWidth': double.parse(_standardWidthController.text),
      'standardLength': double.parse(_standardLengthController.text),
      'standardUnit': _standardUnit,
      'pricePerSqm': _pricePerSqmController.text.isNotEmpty 
          ? double.parse(_pricePerSqmController.text) 
          : 0,
      'pricingUnit': 'sqm',
      'wasteThreshold': double.parse(_wasteThresholdController.text),
      'types': woodTypes.map((t) => {
        'name': t.name,
        if (t.pricePerSqm != null) 'pricePerSqm': t.pricePerSqm,
      }).toList(),
    };

    final result = await _materialService.createMaterial(request);

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wood material created successfully')),
      );
      Navigator.pop(context);
      Navigator.pop(context); // Go back to materials list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to create material'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addWoodType() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final priceController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Wood Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Type Name *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Oak, Pine',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per m² (optional)',
                  border: OutlineInputBorder(),
                  prefixText: '₦',
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
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    woodTypes.add(
                      WoodType(
                        name: nameController.text.trim(),
                        pricePerSqm: priceController.text.isNotEmpty
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
  }

  void _editWoodType(int index) {
    final type = woodTypes[index];
    final nameController = TextEditingController(text: type.name);
    final priceController = TextEditingController(
      text: type.pricePerSqm?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Wood Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Type Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per m²',
                  border: OutlineInputBorder(),
                  prefixText: '₦',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => woodTypes.removeAt(index));
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  woodTypes[index] = WoodType(
                    name: nameController.text.trim(),
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
            // Info Banner
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
                      'Wood materials are priced per square meter. Add different wood types with specific prices.',
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

            // Basic Information
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

            // Standard Dimensions
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
                    hintText: 'Leave empty if types have different prices',
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
                    helperText: 'Used to calculate material waste',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Wood Types
            _buildWoodTypesSection(),
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
                        'Create Wood Material',
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