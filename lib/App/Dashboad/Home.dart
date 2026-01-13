import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wworker/App/Dashboad/Widget/customDash.dart';
import 'package:wworker/App/Dashboad/Widget/emptyQuote.dart';
import 'package:wworker/App/Invoice/View/clients_home.dart';
import 'package:wworker/App/Order/View/QuoforOrder.dart';
import 'package:wworker/App/Order/View/allOrders.dart';
import 'package:wworker/App/Product/UI/addProduct.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';
import 'package:wworker/App/Quotation/Model/ProductModel.dart';
import 'package:wworker/App/Quotation/Providers/ProductProvider.dart';
import 'package:wworker/App/Quotation/Providers/QuotationProvider.dart';
import 'package:wworker/App/Quotation/UI/AllclientQuotations.dart';
import 'package:wworker/App/Quotation/UI/Quotations.dart';
import 'package:wworker/App/Quotation/UI/existingProduct.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/App/Quotation/Widget/Optionmodal.dart';
import 'package:wworker/App/Sales/Views/salesHome.dart';
import 'package:wworker/App/Staffing/View/Notification.dart';
import 'package:wworker/App/Staffing/View/addCompany.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
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
    final notifier = ref.read(quotationProvider.notifier);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData, // ✅ Refresh both
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting with name
                            CustomText(
                              title: "${_getGreeting()}, $fullname!",
                              titleFontSize: 20,
                              titleFontWeight: FontWeight.w600,
                              titleColor: const Color(0xFF302E2E),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),

                            // Active company OR create company prompt
                            if (hasCompany)
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      companyName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF8B4513),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CreateCompanyScreen(),
                                    ),
                                  ).then((_) {
                                    _loadUserData();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_business,
                                        size: 14,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Create Company',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              hasCompany
                                  ? "Ready to create amazing woodwork quotations?"
                                  : "Create a company to get started",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Notification bell
                      GestureDetector(
                        onTap: () {
                          Nav.push(NotificationsPage());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

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
                          Nav.push(AddProduct());
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
                          Nav.push(AllClientQuotations());
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

  // ✅ Build quotations section with API data
  Widget _buildQuotationsSection() {
    final notifier = ref.read(quotationProvider.notifier);

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
          titleFontSize: 17,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              title: "Recent Products",
              textAlign: TextAlign.left,
              titleFontSize: 17,
            ),
            TextButton(onPressed: null, child: const Text("View All")),
          ],
        ),
        const SizedBox(height: 10),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              title: "Recent Products",
              textAlign: TextAlign.left,
              titleFontSize: 17,
            ),
            TextButton(
              onPressed: () {
                Nav.push(const SelectExistingProductScreen());
              },
              child: const Text(
                "View All",
                style: TextStyle(color: Color(0xFF8B4513)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF8B4513).withOpacity(0.2),
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: const Color(0xFF8B4513).withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No products yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add products to get started',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title: "Recent Products",
            textAlign: TextAlign.left,
            titleFontSize: 17,
          ),
          TextButton(
            onPressed: () {
              Nav.push(const SelectExistingProductScreen());
            },
            child: const Text(
              "View All",
              style: TextStyle(color: Color(0xFF8B4513)),
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),

      SizedBox(
        height: 135,
        child: products.length == 1
            ? Row(
                children: [
                  // Shadow card 1 (most faded)
                  Opacity(
                    opacity: 0.3,
                    child: _buildProductCard(products[0], () {}),
                  ),
                  const SizedBox(width: 12),
                  // Shadow card 2 (medium faded)
                  Opacity(
                    opacity: 0.5,
                    child: _buildProductCard(products[0], () {}),
                  ),
                  const SizedBox(width: 12),
                  // Actual product card
                  _buildProductCard(products[0], () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProduct(
                          existingProduct: products[0] as ProductModel?,
                        ),
                      ),
                    );
                  }),
                ],
              )
            : Builder(
                builder: (context) {
                  final scrollController = ScrollController();

                  // Auto-scroll setup
                  Future.delayed(Duration.zero, () {
                    Timer.periodic(const Duration(seconds: 2), (timer) {
                      if (scrollController.hasClients) {
                        final maxScroll =
                            scrollController.position.maxScrollExtent;
                        final currentScroll = scrollController.offset;
                        final nextScroll =
                            currentScroll + 112; // width + padding

                        if (nextScroll >= maxScroll) {
                          scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          scrollController.animateTo(
                            nextScroll,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    });
                  });

                  return ListView.builder(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length > 10 ? 10 : products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildProductCard(product, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProduct(
                                existingProduct: product as ProductModel?,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  );
                },
              ),
      ),
    ],
  );
}



// Helper method to build product card
Widget _buildProductCard(dynamic product, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: product.image.isNotEmpty
                ? Image.network(
                    product.image,
                    height: 70,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey,
                    ),
                  ),
          ),
          // Product name
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
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
                    fontSize: 10,
                    color: Colors.grey.shade600,
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






  Widget _buildGetStartedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B4513).withOpacity(0.1),
            const Color(0xFF8B4513).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B4513).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 48,
            color: const Color(0xFF8B4513).withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Get Started Creating Quotations!',
            style: TextStyle(
              fontSize: 18,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
              color: Colors.red.shade100.withOpacity(0.5),
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
        title: const Text('No Company'),
        content: const Text(
          'You need to create or join a company to access this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
              ).then((_) => _loadUserData());
            },
            child: const Text(
              'Create Company',
              style: TextStyle(color: Color(0xFF8B4513)),
            ),
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
        color: const Color(0xFF8B4513).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B4513).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: const Color(0xFF8B4513).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Company Yet',
            style: TextStyle(
              fontSize: 18,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
