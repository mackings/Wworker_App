import 'package:flutter/material.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/Constant/colors.dart';

class CreateGlobalFoamMaterialPage extends StatefulWidget {
  const CreateGlobalFoamMaterialPage({super.key});

  @override
  State<CreateGlobalFoamMaterialPage> createState() =>
      _CreateGlobalFoamMaterialPageState();
}

class _CreateGlobalFoamMaterialPageState
    extends State<CreateGlobalFoamMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final PlatformOwnerService _service = PlatformOwnerService();

  final TextEditingController _nameController = TextEditingController(
    text: 'Foam',
  );
  final TextEditingController _standardWidthController =
      TextEditingController();
  final TextEditingController _standardLengthController =
      TextEditingController();
  final TextEditingController _pricePerSqmController = TextEditingController();
  final TextEditingController _wasteThresholdController = TextEditingController(
    text: '0.75',
  );

  String _standardUnit = 'inches';
  String? _imagePath;
  bool isCreating = false;

  List<FoamVariant> foamVariants = [];

  @override
  void initState() {
    super.initState();
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final variantsWithPrices = foamVariants
        .where((v) => v.pricePerSqm != null)
        .toList();
    if (variantsWithPrices.isEmpty && _pricePerSqmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please set a base price or at least one variant price',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isCreating = true);

    final result = await _service.createGlobalMaterial(
      name: _nameController.text.trim(),
      category: 'FOAM',
      imagePath: _imagePath,
      standardWidth: double.parse(_standardWidthController.text),
      standardLength: double.parse(_standardLengthController.text),
      standardUnit: _standardUnit,
      pricePerSqm: _pricePerSqmController.text.isNotEmpty
          ? double.parse(_pricePerSqmController.text)
          : 0,
      pricingUnit: 'sqm',
      wasteThreshold: double.parse(_wasteThresholdController.text),
      foamVariants: foamVariants
          .map(
            (v) => {
              'thickness': v.thickness,
              'thicknessUnit': v.thicknessUnit,
              'density': v.density,
              'width': v.width,
              'length': v.length,
              'dimensionUnit': v.dimensionUnit,
              if (v.pricePerSqm != null) 'pricePerSqm': v.pricePerSqm,
            },
          )
          .toList(),
    );

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

  void _addFoamVariant() {
    showDialog(
      context: context,
      builder: (context) {
        final thicknessController = TextEditingController();
        final widthController = TextEditingController();
        final lengthController = TextEditingController();
        final priceController = TextEditingController();
        String density = 'ordinary';
        String thicknessUnit = 'inches';
        String dimensionUnit = 'inches';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Foam Variant'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: thicknessController,
                      decoration: const InputDecoration(
                        labelText: 'Thickness *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: thicknessUnit,
                      decoration: const InputDecoration(
                        labelText: 'Thickness Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'inches',
                          child: Text('Inches'),
                        ),
                        DropdownMenuItem(
                          value: 'mm',
                          child: Text('Millimeters (mm)'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => thicknessUnit = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: density,
                      decoration: const InputDecoration(
                        labelText: 'Density',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ordinary',
                          child: Text('Ordinary'),
                        ),
                        DropdownMenuItem(value: 'lemon', child: Text('Lemon')),
                        DropdownMenuItem(value: 'grey', child: Text('Grey')),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => density = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: widthController,
                      decoration: const InputDecoration(
                        labelText: 'Width *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lengthController,
                      decoration: const InputDecoration(
                        labelText: 'Length *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: dimensionUnit,
                      decoration: const InputDecoration(
                        labelText: 'Dimension Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'inches',
                          child: Text('Inches'),
                        ),
                        DropdownMenuItem(
                          value: 'mm',
                          child: Text('Millimeters (mm)'),
                        ),
                        DropdownMenuItem(
                          value: 'cm',
                          child: Text('Centimeters (cm)'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => dimensionUnit = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per Sqm (Optional)',
                        border: OutlineInputBorder(),
                        prefixText: '₦',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                    final thickness = double.tryParse(thicknessController.text);
                    final width = double.tryParse(widthController.text);
                    final length = double.tryParse(lengthController.text);
                    if (thickness == null || width == null || length == null)
                      return;

                    setState(() {
                      foamVariants.add(
                        FoamVariant(
                          thickness: thickness,
                          thicknessUnit: thicknessUnit,
                          density: density,
                          width: width,
                          length: length,
                          dimensionUnit: dimensionUnit,
                          pricePerSqm: priceController.text.isNotEmpty
                              ? double.tryParse(priceController.text)
                              : null,
                        ),
                      );
                    });
                    Navigator.pop(context);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Create Foam Material",
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
              onImageSelected: (image) {
                setState(() => _imagePath = image?.path);
              },
            ),
            const SizedBox(height: 16),
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
                  const Icon(Icons.airlines, color: Color(0xFF4A90E2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Foam materials are priced per square meter. Add different density and thickness variants.',
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
            _buildSectionCard('Basic Information', [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
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
                  DropdownMenuItem(
                    value: 'mm',
                    child: Text('Millimeters (mm)'),
                  ),
                  DropdownMenuItem(
                    value: 'cm',
                    child: Text('Centimeters (cm)'),
                  ),
                  DropdownMenuItem(value: 'm', child: Text('Meters (m)')),
                  DropdownMenuItem(value: 'inches', child: Text('Inches (in)')),
                  DropdownMenuItem(value: 'ft', child: Text('Feet (ft)')),
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
            ]),
            const SizedBox(height: 16),
            _buildFoamVariantsSection(),
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
                'Foam Variants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF302E2E),
                ),
              ),
              TextButton.icon(
                onPressed: _addFoamVariant,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (foamVariants.isEmpty)
            const Text(
              'No foam variants added yet.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              children: foamVariants.map((variant) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${variant.thickness} ${variant.thicknessUnit} • ${variant.density}',
                        ),
                      ),
                      Text(
                        variant.pricePerSqm != null
                            ? '₦${variant.pricePerSqm}'
                            : 'No price',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => foamVariants.remove(variant));
                        },
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
