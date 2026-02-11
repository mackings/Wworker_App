import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/Model/platform_owner_model.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

class PendingMaterialsPage extends ConsumerStatefulWidget {
  const PendingMaterialsPage({super.key});

  @override
  ConsumerState<PendingMaterialsPage> createState() =>
      _PendingMaterialsPageState();
}

class _PendingMaterialsPageState extends ConsumerState<PendingMaterialsPage> {
  final PlatformOwnerService _service = PlatformOwnerService();
  final TextEditingController _searchController = TextEditingController();

  List<PendingMaterial> materials = [];
  MaterialPaginationInfo? pagination;
  bool isLoading = true;
  String? error;

  int currentPage = 1;
  String? filterCategory;
  String? searchQuery;

  List<String> _categoryOptions = [];
  final NumberFormat _moneyFmt = NumberFormat('#,##0.##');

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await _service.getPendingMaterials(
        page: currentPage,
        limit: 20,
        companyName: searchQuery,
        category: filterCategory,
      );

      if (result['success'] == true) {
        final loaded = (result['data'] as List)
            .map((item) => PendingMaterial.fromJson(item))
            .toList();

        final nextCategories = <String>{
          ..._categoryOptions,
          ...loaded.map((m) => m.category.trim()).where((c) => c.isNotEmpty),
        }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        setState(() {
          materials = loaded;
          _categoryOptions = nextCategories;
          pagination = MaterialPaginationInfo.fromJson(
            result['pagination'] ?? {},
          );
          isLoading = false;
        });
      } else {
        setState(() {
          error = result['message'] ?? 'Failed to load materials';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _approveMaterial(PendingMaterial material) async {
    final notes = await _showNotesSheet(
      title: 'Approve Material',
      helperText: 'Add optional notes for the company.',
      optional: true,
      confirmLabel: 'Approve',
      confirmColor: ColorsApp.btnColor,
    );
    if (notes == null) return;

    final result = await _service.approveMaterial(material.id, notes: notes);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Material approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMaterials();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to approve material'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectMaterial(PendingMaterial material) async {
    final reason = await _showNotesSheet(
      title: 'Reject Material',
      helperText: 'Provide a clear reason for rejection.',
      optional: false,
      confirmLabel: 'Reject',
      confirmColor: ColorsApp.btnColor.withOpacity(0.9),
    );
    if (!mounted) return;
    if (reason == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejection reason is required')),
      );
      return;
    }

    final result = await _service.rejectMaterial(material.id, reason: reason);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Material rejected successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadMaterials();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to reject material'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showNotesSheet({
    required String title,
    required String helperText,
    required bool optional,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final controller = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.openSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorsApp.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      helperText,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: optional
                            ? 'Optional notes...'
                            : 'Rejection reason *',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ColorsApp.btnColor,
                              side: BorderSide(color: ColorsApp.btnColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: confirmLabel,
                            backgroundColor: confirmColor,
                            onPressed: () {
                              final text = controller.text.trim();
                              Navigator.pop(context, text);
                            },
                          ),
                        ),
                      ],
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

  void _openImagePreview(PendingMaterial material) {
    final imageUrl = material.image;
    if (imageUrl == null || imageUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: 'material-image-${material.id}',
              child: InteractiveViewer(child: Image.network(imageUrl)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pending Materials',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFiltersHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMaterials,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? _buildErrorView()
                  : materials.isEmpty
                  ? _buildEmptyView()
                  : _buildMaterialsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersHeader() {
    return Container(
      color: ColorsApp.bgColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Materials',
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorsApp.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Approve or reject materials submitted by companies.',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by company name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = null);
                              _loadMaterials();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: ColorsApp.bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (value) {
                    setState(
                      () => searchQuery = value.isNotEmpty ? value : null,
                    );
                    _loadMaterials();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      ..._categoryOptions.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(cat, cat),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = filterCategory == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? ColorsApp.btnColor : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          filterCategory = isSelected ? null : value;
          currentPage = 1;
        });
        _loadMaterials();
      },
      selectedColor: ColorsApp.btnColor.withOpacity(0.16),
      checkmarkColor: ColorsApp.btnColor,
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            error ?? 'An error occurred',
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loadMaterials, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Materials',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery != null || filterCategory != null
                ? 'Try adjusting your filters'
                : 'All materials have been reviewed',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: materials.length + 1,
      itemBuilder: (context, index) {
        if (index == materials.length) {
          return _buildPaginationInfo();
        }
        return _buildMaterialCard(materials[index]);
      },
    );
  }

  Widget _buildMaterialCard(PendingMaterial material) {
    final hasTypePricing = (material.types ?? []).any((t) => t.pricePerSqm > 0);
    final hasFoamVariantPricing = (material.foamVariants ?? []).any(
      (v) => v.pricePerSqm > 0,
    );

    final isPriced =
        material.isPriced ??
        ((material.unitPrice ?? 0) > 0 ||
            (material.pricePerSqm ?? 0) > 0 ||
            hasTypePricing ||
            hasFoamVariantPricing);

    final effectiveUnitPrice =
        material.unitPrice ?? material.pricePerUnit ?? material.catalogPrice;
    final unitLabel = (material.pricingUnit ?? material.unit)?.trim();

    String? fmtMoney(num? v) {
      if (v == null) return null;
      return _moneyFmt.format(v);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMaterialImage(material),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        material.category,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    if (!isPriced) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'UNPRICED',
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (material.isGlobal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.public,
                              size: 14,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GLOBAL',
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  material.name,
                  style: GoogleFonts.openSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorsApp.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(
                      Icons.business,
                      material.companyName,
                      Colors.blue,
                    ),
                    if (material.submittedBy != null)
                      _buildMetaChip(
                        Icons.person,
                        material.submittedBy!.fullname,
                        Colors.grey,
                      ),
                    if (material.subCategory != null &&
                        material.subCategory!.trim().isNotEmpty)
                      _buildMetaChip(
                        Icons.layers_outlined,
                        material.subCategory!.trim(),
                        Colors.deepPurple,
                      ),
                    if (material.size != null &&
                        material.size!.trim().isNotEmpty)
                      _buildMetaChip(
                        Icons.straighten,
                        material.size!.trim(),
                        Colors.teal,
                      ),
                    if (material.unit != null &&
                        material.unit!.trim().isNotEmpty)
                      _buildMetaChip(
                        Icons.inventory_2_outlined,
                        material.unit!.trim(),
                        Colors.indigo,
                      ),
                    if (material.color != null &&
                        material.color!.trim().isNotEmpty)
                      _buildMetaChip(
                        Icons.palette_outlined,
                        material.color!.trim(),
                        Colors.pink,
                      ),
                    if (material.thickness != null)
                      _buildMetaChip(
                        Icons.line_weight_outlined,
                        '${material.thickness}${material.thicknessUnit != null ? ' ${material.thicknessUnit}' : ''}',
                        Colors.brown,
                      ),
                  ],
                ),
                if (effectiveUnitPrice != null) ...[
                  const SizedBox(height: 12),
                  _buildPriceRow(
                    '₦${fmtMoney(effectiveUnitPrice)}/${unitLabel ?? 'unit'}',
                  ),
                ],
                if (material.pricePerSqm != null) ...[
                  const SizedBox(height: 12),
                  _buildPriceRow('₦${fmtMoney(material.pricePerSqm)}/sqm'),
                ],
                if (effectiveUnitPrice == null &&
                    material.pricePerSqm == null &&
                    hasTypePricing) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Type Pricing',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ColorsApp.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...material.types!
                      .where((t) => t.pricePerSqm > 0)
                      .take(6)
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildPriceRow(
                            '${t.name}: ₦${fmtMoney(t.pricePerSqm)}/sqm',
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveMaterial(material),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsApp.btnColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectMaterial(material),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorsApp.btnColor,
                      side: BorderSide(color: ColorsApp.btnColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialImage(PendingMaterial material) {
    final imageUrl = material.image;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? GestureDetector(
                onTap: () => _openImagePreview(material),
                child: Hero(
                  tag: 'material-image-${material.id}',
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              )
            : Container(
                color: Colors.grey.shade100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No image uploaded',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String priceLabel) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.attach_money,
            size: 14,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Price: $priceLabel',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationInfo() {
    if (pagination == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'Page ${pagination!.page} of ${pagination!.pages}',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorsApp.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${pagination!.total} materials',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
