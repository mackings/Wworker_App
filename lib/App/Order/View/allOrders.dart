import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wworker/App/Order/Api/OrderService.dart';
import 'package:wworker/App/Order/Model/orderModel.dart' hide OrderService;
import 'package:wworker/App/Order/Widget/AssignStaffSheet.dart';
import 'package:wworker/App/Order/Widget/Order_card.dart';
import 'package:wworker/App/Order/Widget/UpdateorderSheet.dart';
import 'package:wworker/GeneralWidgets/UI/guide_help.dart';

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

const _surface = Color(0xFFFAF7F3);
const _primary = Color(0xFFA16438);
const _text = Color(0xFF211D1A);
const _muted = Color(0xFF756A61);
const _border = Color(0xFFE8DED6);

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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFA16438)),
      ),
    );

    final result = await _orderService.deleteOrder(order.id);

    if (!mounted) return;
    navigator.pop();

    if (result['success'] == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
    } else {
      messenger.showSnackBar(
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

      final statusOk =
          statusFilter == null || status == _normalize(statusFilter!);

      return statusOk;
    }).toList();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _text,
        title: const Text("All Orders"),
        titleTextStyle: GoogleFonts.openSans(
          color: _text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
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
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (errorMessage != null) {
      return _StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load orders',
        message: errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadOrders,
      );
    }

    if (orders.isEmpty) {
      return const _StateMessage(
        icon: Icons.shopping_bag_outlined,
        title: 'No orders found',
        message: 'Approved quotations will appear here after an order is made.',
      );
    }

    final filteredOrders = _filteredOrders();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        itemCount: filteredOrders.isEmpty ? 2 : filteredOrders.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _OrdersHeader(
                  total: orders.length,
                  visible: filteredOrders.length,
                ),
                _buildFilterBar(),
              ],
            );
          }

          if (filteredOrders.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  "No orders match these filters",
                  style: GoogleFonts.openSans(color: _muted, fontSize: 13),
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
            onAssignStaff: () => _showAssignStaffSheet(order),
            showFinancialInfo: false,
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final statusOptions = _availableStatusFilters();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filters",
            style: GoogleFonts.openSans(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
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
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: _muted,
              fontWeight: FontWeight.w500,
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
          border: Border.all(
            color: selected ? const Color(0xFFA16438) : _border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 11,
            color: selected ? Colors.white : _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  final int total;
  final int visible;

  const _OrdersHeader({required this.total, required this.visible});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E211A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders',
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  visible == total
                      ? '$total active order${total == 1 ? '' : 's'}'
                      : 'Showing $visible of $total orders',
                  style: GoogleFonts.openSans(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38, color: _primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
}
