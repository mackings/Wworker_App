import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color authSurface = Color(0xFFFAF7F3);
const Color authInk = Color(0xFF211D1A);
const Color authMuted = Color(0xFF756A61);
const Color authBrand = Color(0xFFA16438);
const Color authBorder = Color(0xFFE8DED6);

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool canPop;
  final Widget? bottom;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.canPop = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authSurface,
      appBar: AppBar(
        backgroundColor: authSurface,
        elevation: 0,
        automaticallyImplyLeading: canPop,
        foregroundColor: authInk,
        surfaceTintColor: authSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthHero(title: title, subtitle: subtitle, icon: icon),
              const SizedBox(height: 26),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
              if (bottom != null) ...[const SizedBox(height: 18), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AuthHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: authBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF8B4513), size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      color: authInk,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      color: authMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthLoadingOverlay extends StatelessWidget {
  final bool visible;

  const AuthLoadingOverlay({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      color: Colors.black.withValues(alpha: 0.28),
      child: const Center(child: CircularProgressIndicator(color: authBrand)),
    );
  }
}
