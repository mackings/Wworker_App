import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' hide OrderService;
import 'package:wworker/App/Order/Widget/Order_card.dart';
import 'package:wworker/App/Order/Widget/addPaymentsheet.dart';
import 'package:wworker/App/Sales/Views/PaymentRecipt.dart';
import 'package:wworker/App/Sales/Widgets/emailBalHSheet.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}


class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final OrderService _orderService = OrderService();
  List<OrderModel> orders = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;
  bool isGridView = false;
  String? paymentFilter;
  String? statusFilter;

  // Financial summary data
  double totalRevenue = 0.0;
  double totalPaid = 0.0;
  double totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _orderService.getAllOrders(page: currentPage);

      if (result['success'] == true) {
        final data = result['data'];
        final List<dynamic> ordersJson = data['orders'] ?? [];
        final pagination = data['pagination'] ?? {};

        setState(() {
          orders = ordersJson.map((e) => OrderModel.fromJson(e)).toList();
          totalPages = pagination['totalPages'] ?? 1;
          _calculateFinancials();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['message'] ?? 'Failed to load orders';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  void _calculateFinancials() {
    totalRevenue = 0.0;
    totalPaid = 0.0;
    totalBalance = 0.0;

    for (var order in orders) {
      totalRevenue += order.totalAmount ?? 0.0;
      totalPaid += order.amountPaid ?? 0.0;
      totalBalance += order.balance ?? 0.0;
    }
  }

  List<OrderModel> _filteredOrders() {
    return orders.where((order) {
      final payment = _normalize(order.paymentStatus);
      final status = _normalize(order.status);

      final paymentOk =
          paymentFilter == null || payment == _normalize(paymentFilter!);
      final statusOk = statusFilter == null || status == _normalize(statusFilter!);

      return paymentOk && statusOk;
    }).toList();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  List<_FilterOption> _availablePaymentFilters() {
    final options = <String, String>{};
    for (final order in orders) {
      final normalized = _normalize(order.paymentStatus);
      if (normalized.isEmpty) {
        continue;
      }
      options.putIfAbsent(normalized, () => _prettyLabel(order.paymentStatus));
    }
    final list = options.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return list
        .map((entry) => _FilterOption(value: entry.key, label: entry.value))
        .toList();
  }

  List<_FilterOption> _availableStatusFilters() {
    return const [
      _FilterOption(value: 'pending', label: 'Pending'),
      _FilterOption(value: 'inprogress', label: 'In Progress'),
      _FilterOption(value: 'completed', label: 'Completed'),
      _FilterOption(value: 'onhold', label: 'On Hold'),
      _FilterOption(value: 'cancelled', label: 'Cancelled'),
    ];
  }

  String _prettyLabel(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (normalized.isEmpty) {
      return value;
    }
    return normalized
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  void _showAddPaymentSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddPaymentSheet(
        order: order,
        onPaymentAdded: () {
          Navigator.pop(context);
          _loadOrders();
        },
      ),
    );
  }

  void _navigateToReceipt(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReceiptPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Sales",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) => const GuideHelpIcon(
              title: "Sales",
              message:
                  "Sales shows revenue, payments, and outstanding balances. "
                  "Open an order to add payments or view receipts. The goal "
                  "is to reconcile what has been paid versus what is owed.",
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA16438)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load sales data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA16438),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No sales data found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFFA16438),
      child: Column(
        children: [
          // Financial Summary Card
          _buildFinancialSummary(),
          _buildFilterBar(),
          const SizedBox(height: 16),
          // Orders List
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final paymentOptions = _availablePaymentFilters();
    final statusOptions = _availableStatusFilters();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "Filters",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => isGridView = !isGridView),
                icon: Icon(
                  isGridView ? Icons.view_list : Icons.grid_view,
                  color: const Color(0xFFA16438),
                ),
                tooltip: isGridView ? "List view" : "Grid view",
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildFilterRow(
            title: "Payment",
            options: paymentOptions,
            selected: paymentFilter,
            onSelected: (value) => setState(() => paymentFilter = value),
          ),
          const SizedBox(height: 8),
          _buildFilterRow(
            title: "Status",
            options: statusOptions,
            selected: statusFilter,
            onSelected: (value) => setState(() => statusFilter = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String title,
    required List<_FilterOption> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: "All",
                  selected: selected == null,
                  onTap: () => onSelected(null),
                ),
                const SizedBox(width: 6),
                ...options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildFilterChip(
                      label: option.label,
                      selected: selected == option.value,
                      onTap: () => onSelected(option.value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? const Color(0xFFA16438) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final list = _filteredOrders();

    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No orders match these filters",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final order = list[index];
          return OrderCard(
            order: order,
            onTap: () => debugPrint("View order: ${order.orderNumber}"),
            onAddPayment: () => _showAddPaymentSheet(order),
            onViewReceipt:
                order.amountPaid > 0 ? () => _navigateToReceipt(order) : null,
            showFinancialInfo: true,
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final order = list[index];
        return OrderCard(
          order: order,
          onTap: () => debugPrint("View order: ${order.orderNumber}"),
          onAddPayment: () => _showAddPaymentSheet(order),
          onViewReceipt:
              order.amountPaid > 0 ? () => _navigateToReceipt(order) : null,
          showFinancialInfo: true,
        );
      },
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFA16438),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
        
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Revenue',
                '₦${totalRevenue.toStringAsFixed(2)}',
                Icons.trending_up,
              ),
              _buildSummaryItem(
                'Amount Paid',
                '₦${totalPaid.toStringAsFixed(2)}',
                Icons.check_circle_outline,
              ),
              _buildSummaryItem(
                'Balance',
                '₦${totalBalance.toStringAsFixed(2)}',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
