import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' hide OrderService;
import 'package:wworker/App/Order/Widget/AssignStaffSheet.dart';
import 'package:wworker/App/Order/Widget/Order_card.dart';
import 'package:wworker/App/Order/Widget/UpdateorderSheet.dart';
import 'package:wworker/App/Order/Widget/addPaymentsheet.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

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
  String? statusFilter;

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

  // NEW: Show Assign Staff Sheet
  void _showAssignStaffSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AssignStaffSheet(
        order: order,
        onAssigned: () {
          Navigator.pop(context);
          _loadOrders(); // Reload to show updated assignment
        },
      ),
    );
  }

  List<OrderModel> _filteredOrders() {
    return orders.where((order) {
      final status = _normalize(order.status);

      final statusOk = statusFilter == null || status == _normalize(statusFilter!);

      return statusOk;
    }).toList();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "All Orders",
          style: TextStyle(
            color: Color(0xFF302E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) => const GuideHelpIcon(
              title: "Orders",
              message:
                  "Orders are created after a quotation is approved. Use this "
                  "screen to track progress, assign staff, update status, and "
                  "record payments. The goal is to keep each job’s timeline "
                  "and payment state accurate.",
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

    final filteredOrders = _filteredOrders();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFFA16438),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.isEmpty ? 2 : filteredOrders.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterBar();
          }

          if (filteredOrders.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  "No orders match these filters",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }

          final order = filteredOrders[index - 1];
          return OrderCard(
            order: order,
            onTap: () {
              // Navigate to order details if you have that page
              debugPrint("View order: ${order.orderNumber}");
            },
            onDelete: order.status != 'completed'
                ? () => _deleteOrder(order)
                : null,
            onUpdateStatus: () => _showUpdateStatusSheet(order),
            onAssignStaff: () => _showAssignStaffSheet(order), // NEW
            showFinancialInfo: false, // Hide financial info in All Orders
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final statusOptions = _availableStatusFilters();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Text(
                "Filters",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
          color: selected ? const Color(0xFFA16438) : Colors.grey.shade200,
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
}
