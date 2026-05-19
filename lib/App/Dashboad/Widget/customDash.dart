import 'package:flutter/material.dart';

class CustomDashboard extends StatelessWidget {
  final List<DashboardIcon> dashboardIcons;

  const CustomDashboard({super.key, required this.dashboardIcons});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            "Quick Actions",
            style: TextStyle(
              color: Color(0xFF211D1A),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 360 ? 2 : 3;
            final itemWidth =
                (width - ((crossAxisCount - 1) * 12)) / crossAxisCount;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dashboardIcons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: itemWidth / 106,
              ),
              itemBuilder: (context, index) {
                final item = dashboardIcons[index];
                return _DashboardItem(
                  title: item.title,
                  icon: item.icon,
                  onTap: item.onTap,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _DashboardItem({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8DED6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF8B4513), size: 24),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF302E2E),
                fontSize: 12,
                height: 1.18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardIcon {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  DashboardIcon({required this.title, required this.icon, this.onTap});
}
