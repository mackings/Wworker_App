import 'package:flutter/material.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/Constant/colors.dart';

class CreateGlobalBoardMaterialPage extends StatefulWidget {
  const CreateGlobalBoardMaterialPage({super.key});

  @override
  State<CreateGlobalBoardMaterialPage> createState() =>
      _CreateGlobalBoardMaterialPageState();
}

class _CreateGlobalBoardMaterialPageState
    extends State<CreateGlobalBoardMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final PlatformOwnerService _service = PlatformOwnerService();

  final TextEditingController _nameController =
      TextEditingController(text: 'Board');
  final TextEditingController _standardWidthController =
      TextEditingController();
  final TextEditingController _standardLengthController =
      TextEditingController();
  final TextEditingController _pricePerSqmController =
      TextEditingController();
  final TextEditingController _wasteThresholdController =
      TextEditingController(text: '0.75');

  String _standardUnit = 'inches';
  String _thicknessUnit = 'mm';
  String? _imagePath;
  bool isCreating = false;

  List<BoardType> boardTypes = [];
  List<ThicknessOption> commonThicknesses = [];

  @override
  void initState() {
    super.initState();
    boardTypes = [
      BoardType(name: 'Mdf', pricePerSqm: null),
      BoardType(name: 'Hdf', pricePerSqm: null),
      BoardType(name: 'Mdf_high_gloss', pricePerSqm: null),
      BoardType(name: 'Hdf_high_gloss', pricePerSqm: null),
      BoardType(name: 'Hdf_straight', pricePerSqm: null),
      BoardType(name: 'Packing_Board', pricePerSqm: null),
      BoardType(name: 'Back_cover', pricePerSqm: null),
      BoardType(name: 'Particle_Board_Light', pricePerSqm: null),
      BoardType(name: 'Particle_Board_thick', pricePerSqm: null),
      BoardType(name: 'eco_board', pricePerSqm: null),
      BoardType(name: 'Marine_board', pricePerSqm: null),
      BoardType(name: 'Halfinch_plywood', pricePerSqm: null),
    ];

    commonThicknesses = [
      ThicknessOption(thickness: 6),
      ThicknessOption(thickness: 9),
      ThicknessOption(thickness: 12),
      ThicknessOption(thickness: 15),
      ThicknessOption(thickness: 18),
      ThicknessOption(thickness: 25),
    ];
  }

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    final typesWithPrices =
        boardTypes.where((t) => t.pricePerSqm != null).toList();
    if (typesWithPrices.isEmpty && _pricePerSqmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a base price or at least one type price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (commonThicknesses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one thickness option'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isCreating = true);

    final result = await _service.createGlobalMaterial(
      name: _nameController.text.trim(),
      category: 'BOARD',
      imagePath: _imagePath,
      standardWidth: double.parse(_standardWidthController.text),
      standardLength: double.parse(_standardLengthController.text),
      standardUnit: _standardUnit,
      pricePerSqm: _pricePerSqmController.text.isNotEmpty
          ? double.parse(_pricePerSqmController.text)
          : 0,
      pricingUnit: 'sqm',
      wasteThreshold: double.parse(_wasteThresholdController.text),
      types: boardTypes
          .map((t) => {
                'name': t.name,
                if (t.pricePerSqm != null) 'pricePerSqm': t.pricePerSqm,
              })
          .toList(),
      commonThicknesses: commonThicknesses
          .map((t) => {
                'thickness': t.thickness,
                'unit': _thicknessUnit,
              })
          .toList(),
    );

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Board material created successfully')),
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
              hintText: _thicknessUnit == 'mm' ? 'e.g., 18' : 'e.g., 0.75',
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
                    commonThicknesses
                        .sort((a, b) => a.thickness.compareTo(b.thickness));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsApp.btnColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _updateTypePrice(int index, String value) {
    setState(() {
      boardTypes[index] = boardTypes[index].copyWith(
        pricePerSqm: value.isEmpty ? null : double.tryParse(value),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: const Text(
          "Create Board Material",
          style: TextStyle(
            color: Colors.white,
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
                color: const Color(0xFFD2691E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD2691E).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_module, color: Color(0xFFD2691E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Board materials include MDF, HDF, plywood and particle boards with various thicknesses.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFD2691E),
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
                    DropdownMenuItem(value: 'mm', child: Text('Millimeters (mm)')),
                    DropdownMenuItem(value: 'cm', child: Text('Centimeters (cm)')),
                    DropdownMenuItem(value: 'm', child: Text('Meters (m)')),
                    DropdownMenuItem(value: 'inches', child: Text('Inches (in)')),
                    DropdownMenuItem(value: 'ft', child: Text('Feet (ft)')),
                  ],
                  onChanged: (value) =>
                      setState(() => _standardUnit = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildThicknessSection(),
            const SizedBox(height: 16),
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
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBoardTypesSection(),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isCreating ? null : _createMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsApp.btnColor,
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
                        'Create Board Material',
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
              TextButton.icon(
                onPressed: _addThickness,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD2691E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _thicknessUnit,
            decoration: const InputDecoration(
              labelText: 'Thickness Unit',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'mm', child: Text('Millimeters (mm)')),
              DropdownMenuItem(value: 'inches', child: Text('Inches')),
              DropdownMenuItem(value: 'cm', child: Text('Centimeters (cm)')),
            ],
            onChanged: (value) => setState(() => _thicknessUnit = value!),
          ),
          const SizedBox(height: 12),
          if (commonThicknesses.isEmpty)
            const Text(
              'No thickness added yet.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: commonThicknesses.map((thickness) {
                return Chip(
                  label: Text('${thickness.thickness} $_thicknessUnit'),
                  onDeleted: () => setState(() {
                    commonThicknesses.remove(thickness);
                  }),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBoardTypesSection() {
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
          const Text(
            'Board Types & Prices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF302E2E),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: boardTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(type.name),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: type.pricePerSqm?.toString() ?? '',
                        decoration: const InputDecoration(
                          prefixText: '₦',
                          hintText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _updateTypePrice(index, value),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class BoardType {
  final String name;
  final double? pricePerSqm;

  BoardType({required this.name, this.pricePerSqm});

  BoardType copyWith({double? pricePerSqm}) {
    return BoardType(name: name, pricePerSqm: pricePerSqm);
  }
}

class ThicknessOption {
  final double thickness;

  ThicknessOption({required this.thickness});
}
