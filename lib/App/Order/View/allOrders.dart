import 'package:flutter/material.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' hide OrderService;
import 'package:wworker/App/Order/Widget/Order_card.dart';
import 'package:wworker/App/Order/Widget/UpdateorderSheet.dart';
import 'package:wworker/App/Order/Widget/addPaymentsheet.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> {
  final OrderService _orderService = OrderService();
  List<OrderModel> orders = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;

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

  Future<void> _deleteOrder(OrderModel order) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFA16438)),
      ),
    );

    final result = await _orderService.deleteOrder(order.id);

    Navigator.pop(context); // Close loading dialog

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders(); // Reload orders
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpdateStatusSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateOrderStatusSheet(
        order: order,
        onStatusUpdated: () {
          Navigator.pop(context);
          _loadOrders();
        },
      ),
    );
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
          "All Orders",
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
              'Failed to load orders',
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
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders found',
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            onTap: () {
              // Navigate to order details if you have that page
              debugPrint("View order: ${order.orderNumber}");
            },
            onDelete: order.status != 'completed'
                ? () => _deleteOrder(order)
                : null,
            onAddPayment: () => _showAddPaymentSheet(order),
            onUpdateStatus: () => _showUpdateStatusSheet(order),
          );
        },
      ),
    );
  }
}
