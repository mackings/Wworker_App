import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wworker/App/Order/Model/orderModel.dart';
import 'package:wworker/Constant/urls.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAddPayment;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onAssignStaff;
  final bool showFinancialInfo;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onDelete,
    this.onAddPayment,
    this.onUpdateStatus,
    this.onViewReceipt,
    this.onAssignStaff,
    this.showFinancialInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    String? image;
    if (order.boms.isNotEmpty && order.boms.first.product.image.isNotEmpty) {
      image = order.boms.first.product.image;
    } else if (order.items.isNotEmpty &&
        (order.items.first['image']?.isNotEmpty ?? false)) {
      image = order.items.first['image'];
    }
    image ??= Urls.woodImg;

    Color statusColor;
    String statusText;

    final normalizedStatus = order.status.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    switch (normalizedStatus) {
      case 'completed':
        statusColor = AppColors.success;
        statusText = 'Completed';
        break;
      case 'inprogress':
        statusColor = AppColors.warning;
        statusText = 'In Progress';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusText = 'Cancelled';
        break;
      case 'onhold':
        statusColor = AppColors.info;
        statusText = 'On Hold';
        break;
      default:
        statusColor = AppColors.primary;
        statusText = 'Pending';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8DED6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderImage(imageUrl: image),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              order.clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.openSans(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(label: statusText, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          color: const Color(0xFF756A61),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: Icons.play_arrow_rounded,
                            label: order.startDate != null
                                ? DateFormat('MMM d').format(order.startDate!)
                                : 'No start',
                          ),
                          _InfoChip(
                            icon: Icons.flag_outlined,
                            label: order.endDate != null
                                ? DateFormat('MMM d').format(order.endDate!)
                                : 'No end',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(context),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete order',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3F3),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (showFinancialInfo) ...[
              const SizedBox(height: 12),
              _FinanceStrip(
                amountPaid: "₦${_formatNumber(order.amountPaid)}",
                balance: "₦${_formatNumber(order.balance)}",
                email: order.email,
              ),
            ],
            if (order.isAssigned) ...[
              const SizedBox(height: 12),
              _AssignedStrip(
                name: order.assignedTo!.displayName,
                position: order.assignedTo!.position,
                onEdit: onAssignStaff,
              ),
            ],
            if (onAddPayment != null ||
                onUpdateStatus != null ||
                onViewReceipt != null ||
                onAssignStaff != null) ...[
              const SizedBox(height: 12),
              if (showFinancialInfo)
                _buildFinancialActions()
              else
                _buildOrderManagementActions(),
            ],
          ],
        ),
      ),
    );
  }

  // Action buttons for Sales page (financial management)
  Widget _buildFinancialActions() {
    return Column(
      children: [
        Row(
          children: [
            if (onAddPayment != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: order.balance > 0 ? onAddPayment : null,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text("Add Payment"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            if (onAddPayment != null && onViewReceipt != null)
              const SizedBox(width: 12),
            if (onViewReceipt != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: order.amountPaid > 0 ? onViewReceipt : null,
                  icon: const Icon(Icons.receipt_outlined, size: 18),
                  label: const Text("View Receipt"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Action buttons for All Orders page (order management)
  Widget _buildOrderManagementActions() {
    return Column(
      children: [
        Row(
          children: [
            if (onUpdateStatus != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUpdateStatus,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text("Update Status"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (onUpdateStatus != null && onAssignStaff != null)
              const SizedBox(width: 12),
            if (onAssignStaff != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignStaff,
                  icon: Icon(
                    order.isAssigned ? Icons.person : Icons.person_add,
                    size: 18,
                  ),
                  label: Text(order.isAssigned ? "Reassign" : "Assign Staff"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete order ${order.orderNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDelete != null) onDelete!();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _OrderImage extends StatelessWidget {
  final String imageUrl;

  const _OrderImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 70,
            color: const Color(0xFFF6F0EB),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 24,
              color: AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.openSans(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF756A61)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.openSans(
              color: const Color(0xFF756A61),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceStrip extends StatelessWidget {
  final String amountPaid;
  final String balance;
  final String email;

  const _FinanceStrip({
    required this.amountPaid,
    required this.balance,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniMetric(label: 'Paid', value: amountPaid),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: 'Balance', value: balance),
              ),
            ],
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 14,
                  color: Color(0xFF756A61),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(
                      color: const Color(0xFF756A61),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            color: const Color(0xFF756A61),
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.openSans(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AssignedStrip extends StatelessWidget {
  final String name;
  final String position;
  final VoidCallback? onEdit;

  const _AssignedStrip({
    required this.name,
    required this.position,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6C7AE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (position.isNotEmpty)
                  Text(
                    position,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(
                      color: const Color(0xFF756A61),
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xFFA16438);
  static const Color textPrimary = Color(0xFF302E2E);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFF7CB342);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}
