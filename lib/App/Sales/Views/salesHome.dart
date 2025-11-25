import 'package:flutter/material.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' hide OrderService;
import 'package:wworker/App/Order/Widget/Order_card.dart';
import 'package:wworker/App/Order/Widget/addPaymentsheet.dart';
import 'package:wworker/App/Sales/Views/PaymentRecipt.dart';
import 'package:wworker/App/Sales/Widgets/emailBalHSheet.dart';


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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF302E2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sales",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
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
          const SizedBox(height: 16),
          // Orders List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTap: () {
                    // Navigate to order details if you have that page
                    debugPrint("View order: ${order.orderNumber}");
                  },
                  onAddPayment: () => _showAddPaymentSheet(order),
                  onViewReceipt: order.amountPaid > 0
                      ? () => _navigateToReceipt(order)
                      : null,
                  showFinancialInfo: true, // Show financial info in Sales
                );
              },
            ),
          ),
        ],
      ),
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
          const Text(
            'Financial Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
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