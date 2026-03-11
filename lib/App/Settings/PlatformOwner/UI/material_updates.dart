import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Database/Model/database_models.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/api_modal_sheet.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';

class MaterialUpdatesPage extends StatefulWidget {
  const MaterialUpdatesPage({super.key});

  @override
  State<MaterialUpdatesPage> createState() => _MaterialUpdatesPageState();
}

class _MaterialUpdatesPageState extends State<MaterialUpdatesPage> {
  final PlatformOwnerService _service = PlatformOwnerService();
  final TextEditingController _searchController = TextEditingController();
  static const int _pageSize = 20;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<_CompanyMaterialSummary> _companies = [];
  List<_CompanyMaterialSummary> _filteredCompanies = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalMaterials = 0;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies({bool reset = true}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _totalPages = 1;
        _companies = [];
        _filteredCompanies = [];
        _totalMaterials = 0;
      } else {
        _isLoadingMore = true;
      }
    });

    final result = await _service.getDatabaseMaterials(
      page: _currentPage,
      limit: _pageSize,
      status: 'approved',
    );

    if (!mounted) return;

    if (result['success'] != true) {
      setState(() {
        _error = result['message']?.toString() ?? 'Failed to load materials';
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    final materials =
        (result['data'] as List<DatabaseMaterial>? ?? const <DatabaseMaterial>[]);
    final grouped = <String, List<DatabaseMaterial>>{};
    for (final material in materials) {
      final companyName = _cleanLabel(material.companyName);
      if (companyName.isEmpty) continue;
      grouped.putIfAbsent(companyName, () => []).add(material);
    }

    final newCompanies = grouped.entries.map((entry) {
      final items = entry.value;
      final categories = items
          .map((item) => _cleanLabel(item.category))
          .where((item) => item.isNotEmpty)
          .toSet();
      final pricedItems = items.where(_hasPrice).length;

      DateTime? latestUpdate;
      for (final item in items) {
        final itemTimestamp = item.updatedAt ?? item.createdAt;
        if (itemTimestamp != null &&
            (latestUpdate == null || itemTimestamp.isAfter(latestUpdate))) {
          latestUpdate = itemTimestamp;
        }
      }

      return _CompanyMaterialSummary(
        companyName: entry.key,
        materialCount: items.length,
        categoryCount: categories.length,
        pricedCount: pricedItems,
        latestMaterialName: items.isNotEmpty ? items.first.name : null,
        latestUpdate: latestUpdate,
      );
    }).toList();

    final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
    final merged = <String, _CompanyMaterialSummary>{
      for (final company in _companies) company.companyName: company,
    };
    for (final company in newCompanies) {
      final existing = merged[company.companyName];
      if (existing == null) {
        merged[company.companyName] = company;
      } else {
        merged[company.companyName] = existing.merge(company);
      }
    }
    final companies = merged.values.toList()
      ..sort(
        (a, b) => a.companyName.toLowerCase().compareTo(
          b.companyName.toLowerCase(),
        ),
      );

    setState(() {
      _companies = companies;
      _totalPages = (pagination['pages'] ?? 1) as int;
      _totalMaterials = (pagination['total'] ?? materials.length) as int;
      _isLoading = false;
      _isLoadingMore = false;
    });
    _applySearch();
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCompanies = _companies;
      } else {
        _filteredCompanies = _companies.where((company) {
          return company.companyName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _isLoadingMore || _currentPage >= _totalPages) return;
    setState(() => _currentPage += 1);
    await _loadCompanies(reset: false);
  }

  bool _hasPrice(DatabaseMaterial material) {
    return (material.pricePerSqm ?? 0) > 0 || (material.pricePerUnit ?? 0) > 0;
  }

  String _cleanLabel(String? input) {
    return (input ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        title: Text(
          'Material Update',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: ColorsApp.btnColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCompanies(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_filteredCompanies.isEmpty)
              _buildEmptyState()
            else
              ..._filteredCompanies.map(_buildCompanyCard),
            if (!_isLoading && _companies.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPaginationCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorsApp.btnColor, ColorsApp.btnColor.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update company material prices from one place.',
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Loaded ${_companies.length} companies from page $_currentPage of $_totalPages. Total materials on the endpoint: $_totalMaterials.',
            style: GoogleFonts.openSans(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search company name',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCompanyCard(_CompanyMaterialSummary company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Nav.push(
          CompanyMaterialUpdatePage(companyName: company.companyName),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ColorsApp.btnColor.withValues(alpha: 0.12),
                    child: Text(
                      company.companyName.isNotEmpty
                          ? company.companyName.substring(0, 1).toUpperCase()
                          : '?',
                      style: GoogleFonts.openSans(
                        color: ColorsApp.btnColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.companyName,
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorsApp.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${company.materialCount} materials • ${company.categoryCount} categories • ${company.pricedCount} priced',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                ],
              ),
              if ((company.latestMaterialName ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Recent material: ${company.latestMaterialName}',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 44, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Failed to load materials',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(color: Colors.red.shade400),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Retry',
            onPressed: _loadCompanies,
            backgroundColor: ColorsApp.btnColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No companies with materials were found in the current result set.',
        textAlign: TextAlign.center,
        style: GoogleFonts.openSans(color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildPaginationCard() {
    final hasMore = _currentPage < _totalPages;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Page $_currentPage of $_totalPages',
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorsApp.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasMore
                ? 'Load the next batch of materials to discover more companies.'
                : 'All available pages have been loaded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: _isLoadingMore ? 'Loading...' : 'Load More Companies',
            onPressed: hasMore && !_isLoadingMore ? _loadNextPage : null,
            loading: _isLoadingMore,
            backgroundColor: ColorsApp.btnColor,
          ),
        ],
      ),
    );
  }
}

class CompanyMaterialUpdatePage extends StatefulWidget {
  final String companyName;

  const CompanyMaterialUpdatePage({super.key, required this.companyName});

  @override
  State<CompanyMaterialUpdatePage> createState() =>
      _CompanyMaterialUpdatePageState();
}

class _CompanyMaterialUpdatePageState extends State<CompanyMaterialUpdatePage> {
  final PlatformOwnerService _service = PlatformOwnerService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _moneyFmt = NumberFormat('#,##0.##');
  static const int _pageSize = 20;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<DatabaseMaterial> _materials = [];
  List<DatabaseMaterial> _filteredMaterials = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials({bool reset = true}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _totalPages = 1;
        _totalItems = 0;
        _materials = [];
        _filteredMaterials = [];
      } else {
        _isLoadingMore = true;
      }
    });

    final result = await _service.getDatabaseMaterials(
      companyName: widget.companyName,
      page: _currentPage,
      limit: _pageSize,
    );

    if (!mounted) return;

    if (result['success'] != true) {
      setState(() {
        _error = result['message']?.toString() ?? 'Failed to load materials';
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    final materials =
        (result['data'] as List<DatabaseMaterial>? ?? const <DatabaseMaterial>[])
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
    final merged = <String, DatabaseMaterial>{
      for (final material in _materials) material.id: material,
      for (final material in materials) material.id: material,
    };
    final nextMaterials = merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    setState(() {
      _materials = nextMaterials;
      _totalPages = (pagination['pages'] ?? 1) as int;
      _totalItems = (pagination['total'] ?? nextMaterials.length) as int;
      _isLoading = false;
      _isLoadingMore = false;
    });
    _applySearch();
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMaterials = _materials;
      } else {
        _filteredMaterials = _materials.where((material) {
          return material.name.toLowerCase().contains(query) ||
              (material.category).toLowerCase().contains(query) ||
              (material.subCategory ?? '').toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _editMaterial(DatabaseMaterial material) async {
    final result = await showModalBottomSheet<_MaterialUpdateResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MaterialPriceEditorSheet(
        material: material,
        service: _service,
      ),
    );

    if (!mounted || result == null) return;

    if (result.success) {
      await ApiModalSheet.showSuccess(result.message);
      if (!mounted) return;
      _loadMaterials();
      return;
    }

    await ApiModalSheet.showError(result.message);
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _isLoadingMore || _currentPage >= _totalPages) return;
    setState(() => _currentPage += 1);
    await _loadMaterials(reset: false);
  }

  String _priceLabel(DatabaseMaterial material) {
    if ((material.pricePerSqm ?? 0) > 0) {
      return 'N${_moneyFmt.format(material.pricePerSqm)} / sqm';
    }
    if ((material.pricePerUnit ?? 0) > 0) {
      final unit = material.pricingUnit.trim().isEmpty
          ? 'unit'
          : material.pricingUnit;
      return 'N${_moneyFmt.format(material.pricePerUnit)} / $unit';
    }
    return 'No price set';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        title: Text(
          widget.companyName,
          style: GoogleFonts.openSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: ColorsApp.btnColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMaterials(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Materials',
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ColorsApp.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review this company\'s material prices and update any item directly. Showing page $_currentPage of $_totalPages, total $_totalItems materials.',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search material name or category',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_filteredMaterials.isEmpty)
              _buildEmptyState()
            else
              ..._filteredMaterials.map((material) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  material.name,
                                  style: GoogleFonts.openSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ColorsApp.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    material.category,
                                    if ((material.subCategory ?? '').trim().isNotEmpty)
                                      material.subCategory!.trim(),
                                  ].join(' • '),
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              material.status,
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetaChip(_priceLabel(material)),
                          if ((material.pricingUnit).trim().isNotEmpty)
                            _buildMetaChip('Pricing unit: ${material.pricingUnit}'),
                          if ((material.unit ?? '').trim().isNotEmpty)
                            _buildMetaChip('Unit: ${material.unit}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Update Price',
                          onPressed: () => _editMaterial(material),
                          backgroundColor: ColorsApp.btnColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (!_isLoading && _materials.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMaterialsPaginationCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _error ?? 'Failed to load materials',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(color: Colors.red.shade400),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Retry',
            onPressed: _loadMaterials,
            backgroundColor: ColorsApp.btnColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No materials found for ${widget.companyName}.',
        textAlign: TextAlign.center,
        style: GoogleFonts.openSans(color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildMaterialsPaginationCard() {
    final hasMore = _currentPage < _totalPages;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Page $_currentPage of $_totalPages',
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorsApp.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasMore
                ? 'Load more materials for ${widget.companyName}.'
                : 'All materials for this company have been loaded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: _isLoadingMore ? 'Loading...' : 'Load More Materials',
            onPressed: hasMore && !_isLoadingMore ? _loadNextPage : null,
            loading: _isLoadingMore,
            backgroundColor: ColorsApp.btnColor,
          ),
        ],
      ),
    );
  }
}

class _MaterialPriceEditorSheet extends StatefulWidget {
  final DatabaseMaterial material;
  final PlatformOwnerService service;

  const _MaterialPriceEditorSheet({
    required this.material,
    required this.service,
  });

  @override
  State<_MaterialPriceEditorSheet> createState() =>
      _MaterialPriceEditorSheetState();
}

class _MaterialPriceEditorSheetState extends State<_MaterialPriceEditorSheet> {
  final NumberFormat _moneyFmt = NumberFormat('#,##0.##');
  late final TextEditingController _pricePerSqmController;
  late final TextEditingController _pricePerUnitController;
  late final TextEditingController _pricingUnitController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pricePerSqmController = TextEditingController(
      text: widget.material.pricePerSqm != null
          ? _moneyFmt.format(widget.material.pricePerSqm)
          : '',
    );
    _pricePerUnitController = TextEditingController(
      text: widget.material.pricePerUnit != null
          ? _moneyFmt.format(widget.material.pricePerUnit)
          : '',
    );
    _pricingUnitController = TextEditingController(
      text: widget.material.pricingUnit,
    );
    _pricePerSqmController.addListener(_formatPricePerSqmInput);
    _pricePerUnitController.addListener(_formatPricePerUnitInput);
  }

  @override
  void dispose() {
    _pricePerSqmController.removeListener(_formatPricePerSqmInput);
    _pricePerUnitController.removeListener(_formatPricePerUnitInput);
    _pricePerSqmController.dispose();
    _pricePerUnitController.dispose();
    _pricingUnitController.dispose();
    super.dispose();
  }

  void _formatPricePerSqmInput() => _formatCurrencyController(
    _pricePerSqmController,
  );

  void _formatPricePerUnitInput() => _formatCurrencyController(
    _pricePerUnitController,
  );

  void _formatCurrencyController(TextEditingController controller) {
    final original = controller.text;
    if (original.isEmpty) return;

    final selection = controller.selection;
    final digits = original.replaceAll(',', '');
    final value = double.tryParse(digits);
    if (value == null) return;

    final hasDecimal = digits.contains('.');
    final formatted = hasDecimal ? _formatDecimalInput(digits) : _moneyFmt.format(value);
    if (formatted == original) return;

    final diff = formatted.length - original.length;
    final nextOffset = (selection.baseOffset + diff).clamp(0, formatted.length);

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  String _formatDecimalInput(String raw) {
    final parts = raw.split('.');
    final whole = parts.first.isEmpty ? '0' : parts.first;
    final formattedWhole = _moneyFmt.format(double.tryParse(whole) ?? 0);
    if (parts.length == 1) return formattedWhole;
    return '$formattedWhole.${parts.sublist(1).join()}';
  }

  double? _parseNumber(String text) {
    final clean = text.replaceAll(',', '').trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  Future<void> _save() async {
    final pricePerSqm = _parseNumber(_pricePerSqmController.text);
    final pricePerUnit = _parseNumber(_pricePerUnitController.text);
    final pricingUnit = _pricingUnitController.text.trim();

    if (pricePerSqm == null && pricePerUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one price to update')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await widget.service.updateCompanyMaterialPrice(
      materialId: widget.material.id,
      pricePerSqm: pricePerSqm,
      pricePerUnit: pricePerUnit,
      pricingUnit: pricingUnit,
      showDialogs: false,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    Navigator.pop(
      context,
      _MaterialUpdateResult(
        success: result['success'] == true,
        message: result['message']?.toString() ??
            (result['success'] == true
                ? 'Material updated successfully'
                : 'Failed to update material'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, viewInsets + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 18),
            Text(
              widget.material.name,
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorsApp.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Update this material price for ${widget.material.companyName ?? 'the company'}.',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            _buildField(
              label: 'Price Per Sqm',
              controller: _pricePerSqmController,
            ),
            const SizedBox(height: 14),
            _buildField(
              label: 'Price Per Unit',
              controller: _pricePerUnitController,
            ),
            const SizedBox(height: 14),
            _buildField(
              label: 'Pricing Unit',
              controller: _pricingUnitController,
              helperText: 'Examples: sqm, piece, sheet, roll',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _isSaving ? 'Saving...' : 'Save Price Update',
                onPressed: _isSaving ? null : _save,
                backgroundColor: ColorsApp.btnColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? helperText,
  }) {
    final isPriceField = label.toLowerCase().contains('price');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ColorsApp.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isPriceField
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: isPriceField
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ]
              : null,
          decoration: InputDecoration(
            hintText: helperText,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyMaterialSummary {
  final String companyName;
  final int materialCount;
  final int categoryCount;
  final int pricedCount;
  final String? latestMaterialName;
  final DateTime? latestUpdate;

  const _CompanyMaterialSummary({
    required this.companyName,
    required this.materialCount,
    required this.categoryCount,
    required this.pricedCount,
    this.latestMaterialName,
    this.latestUpdate,
  });

  _CompanyMaterialSummary merge(_CompanyMaterialSummary other) {
    return _CompanyMaterialSummary(
      companyName: companyName,
      materialCount: materialCount + other.materialCount,
      categoryCount: categoryCount > other.categoryCount
          ? categoryCount
          : other.categoryCount,
      pricedCount: pricedCount + other.pricedCount,
      latestMaterialName: other.latestMaterialName ?? latestMaterialName,
      latestUpdate: _latestDate(latestUpdate, other.latestUpdate),
    );
  }

  static DateTime? _latestDate(DateTime? left, DateTime? right) {
    if (left == null) return right;
    if (right == null) return left;
    return left.isAfter(right) ? left : right;
  }
}

class _MaterialUpdateResult {
  final bool success;
  final String message;

  const _MaterialUpdateResult({
    required this.success,
    required this.message,
  });
}
