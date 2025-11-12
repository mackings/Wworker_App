import 'package:flutter/material.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';


class CustomDashboard extends StatelessWidget {
  final List<DashboardIcon> dashboardIcons;

  const CustomDashboard({
    super.key,
    required this.dashboardIcons,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth < 360) {
      crossAxisCount = 2; // very small phones
    } else if (screenWidth < 900) {
      crossAxisCount = 3; // normal phones and small tablets
    } else if (screenWidth < 1200) {
      crossAxisCount = 4; // medium screens
    } else {
      crossAxisCount = 5; // large desktop
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: CustomText(
            title: "Quick Actions",
            titleFontSize: 16,
          ),
        ),

        // Wrap GridView in LayoutBuilder for better responsiveness
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dashboardIcons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
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

  const _DashboardItem({
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0x7FEDD0BB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF8B4513),
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 6),
          CustomText(subtitle: title, subtitleFontSize: 13),
        ],
      ),
    );
  }
}

class DashboardIcon {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  DashboardIcon({
    required this.title,
    required this.icon,
    this.onTap,
  });
}
