import 'dart:async';

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
  static const String _globalScopeName = 'GLOBAL';

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
      companyName: _globalScopeName,
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
    final globalMaterials = materials
        .where((material) => material.isGlobal)
        .toList();
    final categories = globalMaterials
        .map((item) => _cleanLabel(item.category))
        .where((item) => item.isNotEmpty)
        .toSet();
    final pricedItems = globalMaterials.where(_hasPrice).length;

    DateTime? latestUpdate;
    for (final item in globalMaterials) {
      final itemTimestamp = item.updatedAt ?? item.createdAt;
      if (itemTimestamp != null &&
          (latestUpdate == null || itemTimestamp.isAfter(latestUpdate))) {
        latestUpdate = itemTimestamp;
      }
    }

    final newCompanies = globalMaterials.isEmpty
        ? <_CompanyMaterialSummary>[]
        : [
            _CompanyMaterialSummary(
              companyName: _globalScopeName,
              materialCount: globalMaterials.length,
              categoryCount: categories.length,
              pricedCount: pricedItems,
              latestMaterialName: globalMaterials.first.name,
              latestUpdate: latestUpdate,
            ),
          ];

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
    setState(() {
      _filteredCompanies = _companies;
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
                  'Update global material prices from one place.',
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
            'Loaded global materials page $_currentPage of $_totalPages. Total global materials on the endpoint: $_totalMaterials.',
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
        hintText: 'Search global materials',
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
        'No global materials were found in the current result set.',
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
                ? 'Load the next batch of global materials.'
                : 'All available global material pages have been loaded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: _isLoadingMore ? 'Loading...' : 'Load More Global Materials',
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
  static const String _allFilter = 'All';
  static const List<String> _statusOptions = <String>[
    _allFilter,
    'approved',
    'pending',
    'rejected',
  ];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<DatabaseMaterial> _materials = [];
  List<DatabaseMaterial> _filteredMaterials = [];
  List<String> _categories = <String>[_allFilter];
  List<String> _subCategories = <String>[_allFilter];
  String _selectedCategory = _allFilter;
  String _selectedSubCategory = _allFilter;
  String _selectedStatus = 'approved';
  bool _pricedOnly = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
      category: _selectedCategory == _allFilter ? null : _selectedCategory,
      status: _selectedStatus == _allFilter ? null : _selectedStatus,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
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
    final categoryMap = <String, String>{_allFilter.toLowerCase(): _allFilter};
    for (final material in nextMaterials) {
      final category = material.category.trim();
      if (category.isEmpty) continue;
      categoryMap.putIfAbsent(category.toLowerCase(), () => category);
    }
    final categories = categoryMap.values.toList()
      ..sort((a, b) {
        if (a == _allFilter) return -1;
        if (b == _allFilter) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    final selectedCategory = categories.any(
      (item) => item.toLowerCase() == _selectedCategory.toLowerCase(),
    )
        ? categories.firstWhere(
            (item) => item.toLowerCase() == _selectedCategory.toLowerCase(),
          )
        : _allFilter;
    final subCategories = _collectSubCategories(
      nextMaterials,
      category: selectedCategory,
    );
    final selectedSubCategory = subCategories.any(
      (item) => item.toLowerCase() == _selectedSubCategory.toLowerCase(),
    )
        ? subCategories.firstWhere(
            (item) => item.toLowerCase() == _selectedSubCategory.toLowerCase(),
          )
        : _allFilter;

    setState(() {
      _materials = nextMaterials;
      _categories = categories;
      _subCategories = subCategories;
      _selectedCategory = selectedCategory;
      _selectedSubCategory = selectedSubCategory;
      _totalPages = (pagination['pages'] ?? 1) as int;
      _totalItems = (pagination['total'] ?? nextMaterials.length) as int;
      _isLoading = false;
      _isLoadingMore = false;
    });
    _applyFilters();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadMaterials();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredMaterials = _materials.where((material) {
        final matchesSearch =
            query.isEmpty ||
            material.name.toLowerCase().contains(query) ||
            material.category.toLowerCase().contains(query) ||
            (material.subCategory ?? '').toLowerCase().contains(query);
        final matchesSubCategory =
            _selectedSubCategory == _allFilter ||
            (material.subCategory ?? '').trim().toLowerCase() ==
                _selectedSubCategory.toLowerCase();
        final matchesPriced = !_pricedOnly || _hasAnyPrice(material);
        return matchesSearch && matchesSubCategory && matchesPriced;
      }).toList();
    });
  }

  Future<void> _onCategoryChanged(String? value) async {
    if (value == null || value == _selectedCategory) return;
    setState(() {
      _selectedCategory = value;
      _selectedSubCategory = _allFilter;
    });
    await _loadMaterials();
  }

  void _onSubCategoryChanged(String? value) {
    if (value == null || value == _selectedSubCategory) return;
    setState(() => _selectedSubCategory = value);
    _applyFilters();
  }

  Future<void> _onStatusChanged(String? value) async {
    if (value == null || value == _selectedStatus) return;
    setState(() => _selectedStatus = value);
    await _loadMaterials();
  }

  void _onPricedOnlyChanged(bool value) {
    setState(() => _pricedOnly = value);
    _applyFilters();
  }

  bool _hasAnyPrice(DatabaseMaterial material) {
    return (material.pricePerSqm ?? 0) > 0 || (material.pricePerUnit ?? 0) > 0;
  }

  List<String> _collectSubCategories(
    List<DatabaseMaterial> materials, {
    required String category,
  }) {
    final map = <String, String>{_allFilter.toLowerCase(): _allFilter};
    for (final material in materials) {
      final materialCategory = material.category.trim();
      if (category != _allFilter &&
          materialCategory.toLowerCase() != category.toLowerCase()) {
        continue;
      }
      final subCategory = (material.subCategory ?? '').trim();
      if (subCategory.isEmpty) continue;
      map.putIfAbsent(subCategory.toLowerCase(), () => subCategory);
    }

    final items = map.values.toList()
      ..sort((a, b) {
        if (a == _allFilter) return -1;
        if (b == _allFilter) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return items;
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
                    widget.companyName == 'GLOBAL'
                        ? 'Global Materials'
                        : 'Company Materials',
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ColorsApp.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.companyName == 'GLOBAL'
                        ? 'Review global material prices and update any item directly. Showing page $_currentPage of $_totalPages, total $_totalItems materials.'
                        : 'Review this company\'s material prices and update any item directly. Showing page $_currentPage of $_totalPages, total $_totalItems materials.',
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
            _buildFilterBar(),
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
                          height: 46,
                          padding: 12,
                          textSize: 14,
                          borderRadius: 12,
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

  Widget _buildFilterBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter(
                label: 'Category',
                value: _selectedCategory,
                items: _categories,
                onChanged: _onCategoryChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownFilter(
                label: 'Sub Category',
                value: _selectedSubCategory,
                items: _subCategories,
                onChanged: _onSubCategoryChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter(
                label: 'Status',
                value: _selectedStatus,
                items: _statusOptions,
                onChanged: _onStatusChanged,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: Text(
              'Priced only',
              style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
            ),
            selected: _pricedOnly,
            onSelected: _onPricedOnlyChanged,
            selectedColor: ColorsApp.btnColor.withValues(alpha: 0.18),
            checkmarkColor: ColorsApp.btnColor,
            side: BorderSide(color: Colors.grey.shade300),
            backgroundColor: Colors.white,
            labelStyle: GoogleFonts.openSans(color: ColorsApp.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = <String>[];
    final seen = <String>{};
    for (final item in items) {
      final normalized = item.trim();
      final key = normalized.toLowerCase();
      if (normalized.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      uniqueItems.add(normalized);
    }
    final selectedValue = uniqueItems.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    )
        ? uniqueItems.firstWhere(
            (item) => item.toLowerCase() == value.toLowerCase(),
          )
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: GoogleFonts.openSans(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        items: uniqueItems.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(fontSize: 13),
            ),
          );
        }).toList(),
        onChanged: onChanged,
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
  late String _selectedPricingUnit;
  late final List<String> _pricingUnitOptions;
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
    _pricingUnitOptions = _resolvePricingUnitOptions(widget.material);
    _selectedPricingUnit = _pricingUnitOptions.contains(widget.material.pricingUnit)
        ? widget.material.pricingUnit
        : _pricingUnitOptions.first;
    _pricePerSqmController.addListener(_formatPricePerSqmInput);
    _pricePerUnitController.addListener(_formatPricePerUnitInput);
  }

  @override
  void dispose() {
    _pricePerSqmController.removeListener(_formatPricePerSqmInput);
    _pricePerUnitController.removeListener(_formatPricePerUnitInput);
    _pricePerSqmController.dispose();
    _pricePerUnitController.dispose();
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

  List<String> _resolvePricingUnitOptions(DatabaseMaterial material) {
    final options = <String>{};
    final pricingUnit = material.pricingUnit.trim();
    if (pricingUnit.isNotEmpty) {
      options.add(pricingUnit);
    }
    final materialUnit = (material.unit ?? '').trim();
    if (materialUnit.isNotEmpty) {
      options.add(materialUnit);
    }
    final standardUnit = (material.standardUnit ?? '').trim();
    if (standardUnit.isNotEmpty) {
      options.add(standardUnit);
    }
    if ((material.pricePerSqm ?? 0) > 0) {
      options.add('sqm');
    }
    if ((material.pricePerUnit ?? 0) > 0) {
      options.add(materialUnit.isNotEmpty ? materialUnit : 'unit');
    }
    if (options.isEmpty) {
      options.add('unit');
    }
    return options.toList();
  }

  Future<void> _save() async {
    final pricePerSqm = _parseNumber(_pricePerSqmController.text);
    final pricePerUnit = _parseNumber(_pricePerUnitController.text);
    final pricingUnit = _selectedPricingUnit.trim();

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
              initialValue: _selectedPricingUnit,
              options: _pricingUnitOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedPricingUnit = value);
              },
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
    TextEditingController? controller,
    String? initialValue,
    List<String>? options,
    ValueChanged<String?>? onChanged,
    String? helperText,
  }) {
    final isPriceField = label.toLowerCase().contains('price');
    final isDropdown = options != null && options.isNotEmpty;

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
        if (isDropdown)
          DropdownButtonFormField<String>(
            initialValue: initialValue,
            items: options.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          )
        else
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
