import 'package:flutter/material.dart';
import 'package:wworker/App/Product/Widget/imgBg.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/Constant/colors.dart';

class CreateGlobalFabricMaterialPage extends StatefulWidget {
  const CreateGlobalFabricMaterialPage({super.key});

  @override
  State<CreateGlobalFabricMaterialPage> createState() =>
      _CreateGlobalFabricMaterialPageState();
}

class _CreateGlobalFabricMaterialPageState
    extends State<CreateGlobalFabricMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final PlatformOwnerService _service = PlatformOwnerService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _pricingUnit = 'piece';
  String? _imagePath;
  bool isCreating = false;

  Future<void> _createMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isCreating = true);

    final result = await _service.createGlobalMaterial(
      name: _nameController.text.trim(),
      category: 'FABRIC',
      imagePath: _imagePath,
      pricePerUnit: double.parse(_priceController.text),
      pricingUnit: _pricingUnit,
      notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
    );

    setState(() => isCreating = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fabric material created successfully')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: const Text(
          "Create Fabric Material",
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
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE91E63).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.checkroom, color: Color(0xFFE91E63)),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Fabric Name *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Leather, Velvet, Ankara',
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                  hintText: 'e.g., color, texture, or usage notes',
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
                        'Create Fabric Material',
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
