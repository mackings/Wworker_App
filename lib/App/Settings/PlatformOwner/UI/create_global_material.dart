import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customTextFormField.dart';

class CreateGlobalMaterial extends ConsumerStatefulWidget {
  const CreateGlobalMaterial({super.key});

  @override
  ConsumerState<CreateGlobalMaterial> createState() =>
      _CreateGlobalMaterialState();
}

class _CreateGlobalMaterialState extends ConsumerState<CreateGlobalMaterial> {
  final PlatformOwnerService _service = PlatformOwnerService();
  final _formKey = GlobalKey<FormState>();

  // Basic Info Controllers
  final nameController = TextEditingController();
  final notesController = TextEditingController();

  // Sheet Material Controllers
  final widthController = TextEditingController();
  final lengthController = TextEditingController();
  final pricePerSqmController = TextEditingController();
  final wasteThresholdController = TextEditingController(text: '0.75');

  // Hardware/Fabric Controllers
  final pricePerUnitController = TextEditingController();

  String? selectedCategory;
  String? selectedUnit = 'inches';
  String? selectedPricingUnit = 'piece';
  bool isLoading = false;

  final List<String> _categories = const [
    'WOOD',
    'BOARD',
    'FOAM',
    'MARBLE',
    'HARDWARE',
    'FABRIC',
    'OTHER'
  ];

  final List<String> _units = const ['inches', 'cm', 'mm', 'm'];
  final List<String> _pricingUnits = const ['piece', 'unit', 'pair', 'set', 'pack'];

  bool get requiresDimensions {
    return selectedCategory != null &&
        ['WOOD', 'BOARD', 'FOAM', 'MARBLE'].contains(selectedCategory);
  }

  bool get requiresUnitPrice {
    return selectedCategory != null &&
        ['HARDWARE', 'FABRIC', 'OTHER'].contains(selectedCategory);
  }

  Future<void> _createGlobalMaterial() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => isLoading = true);

    try {
      final result = await _service.createGlobalMaterial(
        name: nameController.text.trim(),
        category: selectedCategory ?? '',
        standardWidth: requiresDimensions && widthController.text.isNotEmpty
            ? double.parse(widthController.text)
            : null,
        standardLength: requiresDimensions && lengthController.text.isNotEmpty
            ? double.parse(lengthController.text)
            : null,
        standardUnit: requiresDimensions ? selectedUnit : null,
        pricePerSqm: requiresDimensions && pricePerSqmController.text.isNotEmpty
            ? double.parse(pricePerSqmController.text)
            : null,
        pricePerUnit: requiresUnitPrice && pricePerUnitController.text.isNotEmpty
            ? double.parse(pricePerUnitController.text)
            : null,
        pricingUnit: requiresUnitPrice ? selectedPricingUnit : null,
        wasteThreshold: requiresDimensions && wasteThresholdController.text.isNotEmpty
            ? double.parse(wasteThresholdController.text)
            : null,
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['message'] ?? 'Global material created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Nav.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create material'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentMaxWidth = screenWidth > 520 ? 520.0 : screenWidth;

    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        elevation: 0,
        title: Text(
          'Create Global Material',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Form(
                key: _formKey,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildInfoStrip(),
                        const SizedBox(height: 16),
                        _buildFormCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899),
            const Color(0xFFEC4899).withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.science,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Material',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a material accessible to all companies on the platform.',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline,
              size: 18,
              color: Color(0xFFEC4899),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Global materials are instantly available to all companies and can only be edited by platform owners.',
              style: GoogleFonts.openSans(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: 'Basic Information',
            subtitle: 'Material name and category',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF667EEA),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Material Name',
            hintText: 'e.g., Premium Mahogany, Cabinet Handles',
            controller: nameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Material name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Category',
            hintText: 'Select material category',
            isDropdown: true,
            dropdownItems: _categories,
            value: selectedCategory,
            onChanged: (value) {
              setState(() => selectedCategory = value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Category is required';
              }
              return null;
            },
          ),

          if (requiresDimensions) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Sheet Dimensions',
              subtitle: 'Standard size for sheet materials',
              icon: Icons.aspect_ratio,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Width',
                    hintText: '48',
                    controller: widthController,
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
                  child: CustomTextField(
                    label: 'Length',
                    hintText: '96',
                    controller: lengthController,
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
            CustomTextField(
              label: 'Unit',
              hintText: 'Select unit',
              isDropdown: true,
              dropdownItems: _units,
              value: selectedUnit,
              onChanged: (value) {
                setState(() => selectedUnit = value);
              },
            ),
          ],

          if (requiresDimensions) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Pricing',
              subtitle: 'Price per square meter',
              icon: Icons.attach_money,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Price per Sqm (₦)',
              hintText: 'e.g., 15000',
              controller: pricePerSqmController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Invalid price';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Waste Threshold',
              hintText: '0.75 (75% usable)',
              controller: wasteThresholdController,
              keyboardType: TextInputType.number,
            ),
          ],

          if (requiresUnitPrice) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(
              title: 'Pricing',
              subtitle: 'Price per unit/piece',
              icon: Icons.attach_money,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Price per Unit (₦)',
              hintText: 'e.g., 500',
              controller: pricePerUnitController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Invalid price';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Pricing Unit',
              hintText: 'Select unit',
              isDropdown: true,
              dropdownItems: _pricingUnits,
              value: selectedPricingUnit,
              onChanged: (value) {
                setState(() => selectedPricingUnit = value);
              },
            ),
          ],

          const SizedBox(height: 24),
          _buildSectionTitle(
            title: 'Additional Notes',
            subtitle: 'Optional details (optional)',
            icon: Icons.notes_outlined,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Notes',
            hintText: 'Any additional information...',
            controller: notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Global Material',
            onPressed: _createGlobalMaterial,
            loading: isLoading,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Cancel',
            outlined: true,
            onPressed: () => Nav.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorsApp.textColor,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    widthController.dispose();
    lengthController.dispose();
    pricePerSqmController.dispose();
    wasteThresholdController.dispose();
    pricePerUnitController.dispose();
    super.dispose();
  }
}
