import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wworker/App/Settings/PlatformOwner/Api/platform_owner_service.dart';
import 'package:wworker/App/Settings/PlatformOwner/Model/platform_owner_model.dart';
import 'package:wworker/Constant/colors.dart';

class AllProductsView extends ConsumerStatefulWidget {
  const AllProductsView({super.key});

  @override
  ConsumerState<AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends ConsumerState<AllProductsView> {
  final PlatformOwnerService _service = PlatformOwnerService();
  final TextEditingController _searchController = TextEditingController();

  List<PendingProduct> products = [];
  PaginationInfo? pagination;
  Map<String, int>? stats;
  bool isLoading = true;
  String? error;

  int currentPage = 1;
  String? filterStatus;
  String? filterCompany;
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await _service.getAllProducts(
        page: currentPage,
        limit: 20,
        status: filterStatus,
        companyName: filterCompany,
        search: searchQuery,
      );

      if (result['success'] == true) {
        setState(() {
          products = (result['data'] as List)
              .map((item) => PendingProduct.fromJson(item))
              .toList();
          stats = Map<String, int>.from(result['stats'] ?? {});
          pagination = PaginationInfo.fromJson(result['pagination']);
          isLoading = false;
        });
      } else {
        setState(() {
          error = result['message'] ?? 'Failed to load products';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.btnColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'All Products',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters Header
          _buildFiltersHeader(),

          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? _buildErrorView()
                  : products.isEmpty
                  ? _buildEmptyView()
                  : _buildProductsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => searchQuery = null);
                        _loadProducts();
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
            onSubmitted: (value) {
              setState(() => searchQuery = value.isNotEmpty ? value : null);
              _loadProducts();
            },
          ),

          const SizedBox(height: 12),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'All',
                  null,
                  (stats?['pending'] ?? 0) +
                      (stats?['approved'] ?? 0) +
                      (stats?['rejected'] ?? 0),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending', stats?['pending'] ?? 0),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Approved',
                  'approved',
                  stats?['approved'] ?? 0,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Rejected',
                  'rejected',
                  stats?['rejected'] ?? 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, int count) {
    final isSelected = filterStatus == value;
    Color chipColor;

    switch (value) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'approved':
        chipColor = Colors.green;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = ColorsApp.btnColor;
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : chipColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? chipColor : chipColor,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          filterStatus = isSelected ? null : value;
          currentPage = 1;
        });
        _loadProducts();
      },
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
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
          ElevatedButton(onPressed: _loadProducts, child: const Text('Retry')),
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
            'No Products Found',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery != null
                ? 'Try adjusting your search'
                : 'No products available',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length + 1,
      itemBuilder: (context, index) {
        if (index == products.length) {
          return _buildPaginationInfo();
        }
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(PendingProduct product) {
    Color statusColor;
    IconData statusIcon;

    switch (product.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Product Image
          if (product.image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: product.image!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge and Product ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            product.status.toUpperCase(),
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.productId,
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Product Name
                Text(
                  product.name,
                  style: GoogleFonts.openSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorsApp.textColor,
                  ),
                ),

                const SizedBox(height: 8),

                // Company and Category
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.companyName,
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsApp.btnColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorsApp.btnColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // Description
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    product.description!,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
            'Total: ${pagination!.total} products',
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
