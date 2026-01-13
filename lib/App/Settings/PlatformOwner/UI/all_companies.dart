import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/Model/platform_owner_model.dart';
import 'package:wworker/App/Settings/PlatformOwner/UI/company_details.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class AllCompaniesPage extends ConsumerStatefulWidget {
  const AllCompaniesPage({super.key});

  @override
  ConsumerState<AllCompaniesPage> createState() => _AllCompaniesPageState();
}

class _AllCompaniesPageState extends ConsumerState<AllCompaniesPage> {
  final PlatformOwnerService _service = PlatformOwnerService();
  final TextEditingController _searchController = TextEditingController();

  List<CompanyInfo> companies = [];
  PaginationInfo? pagination;
  bool isLoading = true;
  String? error;

  int currentPage = 1;
  String? searchQuery;
  bool? filterActive;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await _service.getAllCompanies(
        page: currentPage,
        limit: 20,
        search: searchQuery,
        isActive: filterActive,
      );

      if (result['success'] == true) {
        setState(() {
          companies = (result['data'] as List)
              .map((item) => CompanyInfo.fromJson(item))
              .toList();
          pagination = PaginationInfo.fromJson(result['pagination']);
          isLoading = false;
        });
      } else {
        setState(() {
          error = result['message'] ?? 'Failed to load companies';
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

  void _onSearch(String query) {
    setState(() {
      searchQuery = query.isNotEmpty ? query : null;
      currentPage = 1;
    });
    _loadCompanies();
  }

  void _onFilterChange(bool? active) {
    setState(() {
      filterActive = active;
      currentPage = 1;
    });
    _loadCompanies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.bgColor,
        elevation: 0,
        title: const CustomText(title: "All Companies"),
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _onSearch,
                ),
                const SizedBox(height: 12),

                // Filter Chips
                Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: filterActive == null,
                      onSelected: (_) => _onFilterChange(null),
                      selectedColor: ColorsApp.btnColor.withOpacity(0.2),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Active'),
                      selected: filterActive == true,
                      onSelected: (_) => _onFilterChange(true),
                      selectedColor: Colors.green.shade100,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Inactive'),
                      selected: filterActive == false,
                      onSelected: (_) => _onFilterChange(false),
                      selectedColor: Colors.red.shade100,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Companies List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCompanies,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? _buildErrorView()
                      : companies.isEmpty
                          ? _buildEmptyView()
                          : _buildCompaniesList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadCompanies,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Companies Found',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery != null
                ? 'Try adjusting your search'
                : 'No companies registered yet',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: companies.length + (pagination != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == companies.length) {
          return _buildPaginationInfo();
        }
        return _buildCompanyCard(companies[index]);
      },
    );
  }

  Widget _buildCompanyCard(CompanyInfo company) {
    return GestureDetector(
      onTap: () => Nav.push(CompanyDetailsPage(companyId: company.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Company Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ColorsApp.btnColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.business,
                    color: ColorsApp.btnColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Company Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorsApp.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company.email,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: company.isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    company.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: company.isActive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),

            // Owner Info
            if (company.owner != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      company.owner!.fullname,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Stats Row
            if (company.stats != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsApp.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Products',
                      company.stats!.products,
                      Icons.inventory_2,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      'Orders',
                      company.stats!.orders,
                      Icons.shopping_cart,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      'Quotations',
                      company.stats!.quotations,
                      Icons.description,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      'Users',
                      company.stats!.users,
                      Icons.people,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: ColorsApp.btnColor),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorsApp.textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildPaginationInfo() {
    if (pagination == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Page ${pagination!.page} of ${pagination!.pages} • Total: ${pagination!.total} companies',
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
