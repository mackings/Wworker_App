import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Dashboad/Widget/customDash.dart';
import 'package:wworker/App/Invoice/View/clients_home.dart';
import 'package:wworker/App/Order/View/QuoforOrder.dart';
import 'package:wworker/App/Order/View/allOrders.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/App/Quotation/Model/ProductModel.dart';
import 'package:wworker/App/Quotation/Providers/ProductProvider.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/App/Quotation/UI/existingProduct.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';
import 'package:wworker/App/Sales/Views/salesHome.dart';
import 'package:wworker/App/Staffing/View/Notification.dart';
import 'package:wworker/App/Staffing/View/addCompany.dart';
import 'package:wworker/App/Database/View/database_home.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  String fullname = '';
  String companyName = '';
  bool hasCompany = false;

  // ✅ Quotations API loading state
  final ClientQuotationService _quotationService = ClientQuotationService();
  List<Quotation> quotations = [];
  bool isLoadingQuotations = true;
  String? quotationError;

  // ✅ Products loading state
  bool isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Get first name from full name
      final fullNameFromPrefs = prefs.getString('fullname') ?? 'User';
      final nameParts = fullNameFromPrefs.trim().split(RegExp(r'\s+'));
      fullname = nameParts.isNotEmpty ? nameParts.first : 'User';

      // Get company name and check if exists
      final storedCompanyName = prefs.getString('companyName');

      if (storedCompanyName != null && storedCompanyName.isNotEmpty) {
        companyName = storedCompanyName;
        hasCompany = true;
      } else {
        companyName = 'No Company';
        hasCompany = false;
      }

      debugPrint("👤 Loaded user: $fullname");
      debugPrint("🏢 Loaded company: $companyName (hasCompany: $hasCompany)");
    });

    // ✅ Load data if user has company
    if (hasCompany) {
      _loadQuotations();
      _loadProducts();
    }
  }

  // ✅ Load quotations from API
  Future<void> _loadQuotations() async {
    setState(() {
      isLoadingQuotations = true;
      quotationError = null;
    });

    try {
      final result = await _quotationService.getAllQuotations();

      if (result['success'] == true) {
        final quotationResponse = QuotationResponse.fromJson(result);
        setState(() {
          quotations = quotationResponse.data;
          isLoadingQuotations = false;
        });
      } else {
        setState(() {
          isLoadingQuotations = false;
          quotationError = result['message'] ?? 'Failed to load quotations';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingQuotations = false;
        quotationError = 'Error: $e';
      });
    }
  }

  // ✅ Load products from provider
  Future<void> _loadProducts() async {
    setState(() => isLoadingProducts = true);
    await ref.read(productProvider.notifier).fetchProducts();
    setState(() => isLoadingProducts = false);
  }

  // ✅ Refresh both quotations and products
  Future<void> _refreshData() async {
    await Future.wait([_loadQuotations(), _loadProducts()]);
  }

  // Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData, // ✅ Refresh both
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(context),
                  const SizedBox(height: 22),

                  CustomDashboard(
                    dashboardIcons: [
                      DashboardIcon(
                        title: "Create Quotation",
                        icon: Icons.calculate,
                        onTap: () {
                          if (!hasCompany) {
                            _showNoCompanyDialog(context);
                            return;
                          }
                          Nav.push(AllQuotations());
                        },
                      ),
                      DashboardIcon(
                        title: "Add Product",
                        icon: Icons.add_box_outlined,
                        onTap: () {
                          if (!hasCompany) {
                            _showNoCompanyDialog(context);
                            return;
                          }
                          Nav.push(const AddProduct(returnToHomeOnSave: true));
                        },
                      ),
                      DashboardIcon(
                        title: "Generate Invoice",
                        icon: Icons.receipt_long_outlined,
                        onTap: () {
                          if (!hasCompany) {
                            _showNoCompanyDialog(context);
                            return;
                          }
                          Nav.push(ClientsHome());
                        },
                      ),
                      DashboardIcon(
                        title: "Database",
                        icon: Icons.list_alt_outlined,
                        onTap: () {
                          if (!hasCompany) {
                            _showNoCompanyDialog(context);
                            return;
                          }
                          Nav.push(const DatabaseHomePage());
                        },
                      ),
                      DashboardIcon(
                        title: "Order",
                        icon: Icons.shopping_cart_outlined,
                        onTap: () {
                          if (!hasCompany) {
                            _showNoCompanyDialog(context);
                            return;
                          }
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => SelectOptionSheet(
                              title: "Select Action",
                              options: [
                                OptionItem(
                                  label: "Create Order",
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SelectQuotationForOrder(),
                                      ),
                                    );
                                  },
                                ),
                                OptionItem(
                                  label: "View Orders",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllOrdersPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      DashboardIcon(
                        title: "Sales",
                        icon: Icons.trending_up_outlined,
                        onTap: () {
                          if (!hasCompany) {
                            _showNoCompanyDialog(context);
                            return;
                          }
                          Nav.push(SalesPage());
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ✅ Recent Quotations Section with API data
                  if (hasCompany) _buildQuotationsSection(),

                  if (!hasCompany) _buildNoCompanyPrompt(),

                  const SizedBox(height: 30),

                  // ✅ Recent Products Section
                  if (hasCompany) _buildProductsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8DED6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
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
                      "${_getGreeting()}, $fullname!",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF211D1A),
                        fontSize: 21,
                        height: 1.16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (hasCompany)
                      _buildCompanyPill()
                    else
                      _buildCreateCompanyPill(context),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => Nav.push(NotificationsPage()),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF8B4513),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasCompany
                ? "Build quotations, orders, invoices, and sales records from one workspace."
                : "Create a company profile to unlock your workspace.",
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_rounded, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8B4513),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCompanyPill(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
        ).then((_) => _loadUserData());
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_business_rounded,
              size: 15,
              color: Colors.orange.shade800,
            ),
            const SizedBox(width: 6),
            Text(
              'Create Company',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Build quotations section with API data
  Widget _buildQuotationsSection() {
    if (isLoadingQuotations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF8B4513)),
        ),
      );
    }

    if (quotationError != null) {
      final errorMessage = quotationError!.toLowerCase();

      if (errorMessage.contains('no') ||
          errorMessage.contains('empty') ||
          errorMessage.contains('not found')) {
        return _buildGetStartedCard();
      }

      return _buildErrorCard(quotationError!);
    }

    if (quotations.isEmpty) {
      return _buildGetStartedCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title: "Recent Quotations",
          textAlign: TextAlign.left,
          titleFontSize: 16,
          titleFontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quotations.length > 5 ? 5 : quotations.length,
          itemBuilder: (context, index) {
            final quotation = quotations[index];
            final firstItem = quotation.items.isNotEmpty
                ? quotation.items.first
                : null;

            return ClientQuotationCard(
              quotation: {
                'clientName': quotation.clientName,
                'phoneNumber': quotation.phoneNumber,
                'description': quotation.description,
                'finalTotal': quotation.finalTotal,
                'status': quotation.status,
                'createdAt': quotation.createdAt.toIso8601String(),
                'quotationNumber': quotation.quotationNumber,
                'items': firstItem != null
                    ? [
                        {
                          'productName': quotation.service.product,
                          'woodType': firstItem.woodType ?? 'N/A',
                          'image': firstItem.image.isNotEmpty
                              ? firstItem.image
                              : Urls.woodImg,
                        },
                      ]
                    : [],
              },
              onDelete: () async {
                _loadQuotations();
              },
            );
          },
        ),
        // const SizedBox(height: 10),
      ],
    );
  }

  // ✅ Build products section
  // ✅ Build products section
  Widget _buildProductsSection() {
    final products = ref.watch(productProvider);

    if (isLoadingProducts) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: "Recent Products", onViewAll: null),
          const SizedBox(height: 12),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            ),
          ),
        ],
      );
    }

    if (products.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: "Recent Products",
            onViewAll: () => Nav.push(const SelectExistingProductScreen()),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8DED6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No products yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF302E2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add products to keep your catalog ready for quotations.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: "Recent Products",
          onViewAll: () => Nav.push(const SelectExistingProductScreen()),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 166,
          child: products.length == 1
              ? Row(
                  children: [
                    _buildProductCard(products[0], () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProduct(
                            existingProduct: products[0] as ProductModel?,
                            returnToHomeOnSave: true,
                          ),
                        ),
                      );
                    }),
                  ],
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length > 10 ? 10 : products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProduct(
                            existingProduct: product as ProductModel?,
                            returnToHomeOnSave: true,
                          ),
                        ),
                      );
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback? onViewAll,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF211D1A),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              "View All",
              style: TextStyle(
                color: onViewAll == null
                    ? Colors.grey.shade400
                    : const Color(0xFF8B4513),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build product card
  Widget _buildProductCard(dynamic product, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 134,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8DED6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF302E2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(dynamic product) {
    final image = (product.image ?? '').toString().trim();
    if (image.isEmpty) return _buildProductImagePlaceholder();

    return Image.network(
      image,
      height: 86,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildProductImagePlaceholder(isLoading: true);
      },
      errorBuilder: (_, __, ___) => _buildProductImagePlaceholder(),
    );
  }

  Widget _buildProductImagePlaceholder({bool isLoading = false}) {
    return Container(
      height: 86,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFFF1F1F1)),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF9E9E9E),
                size: 24,
              ),
            ),
    );
  }

  Widget _buildGetStartedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B4513).withValues(alpha: 0.10),
            const Color(0xFF8B4513).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B4513).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 48,
            color: const Color(0xFF8B4513).withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Get Started Creating Quotations!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t created any quotations yet. Start by creating your first quotation for your woodwork projects.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Nav.push(AllQuotations());
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create First Quotation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No company dialog
  void _showNoCompanyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Color(0xFF8B4513),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No Company Found',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: const Text(
          'Create a company first to unlock quotations, invoices, and project tracking.',
          style: TextStyle(height: 1.4, color: Color(0xFF5B5B5B)),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Maybe Later',
                  onPressed: () => Navigator.pop(context),
                  outlined: true,
                  icon: Icons.close_rounded,
                  height: 56,
                  padding: 14,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'Create Now',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateCompanyScreen(),
                      ),
                    ).then((_) => _loadUserData());
                  },
                  icon: Icons.add_business_rounded,
                  height: 56,
                  padding: 14,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // No company prompt widget
  Widget _buildNoCompanyPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF8B4513).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B4513).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: const Color(0xFF8B4513).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Company Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a company to start managing your woodwork projects',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCompanyScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
              icon: const Icon(Icons.add_business, color: Colors.white),
              label: const Text(
                'Create Company',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
