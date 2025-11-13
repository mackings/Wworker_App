import 'package:flutter/material.dart';

class CustomSigninAlt extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onLoginTap;

  const CustomSigninAlt({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
    this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Divider(color: Color(0xFFD3D3D3), thickness: 1.5),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'or Continue with',
                style: TextStyle(
                  color: Color(0xFF302E2E),
                  fontSize: 14,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFD3D3D3), thickness: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Google + Apple buttons
        Row(
          children: [
            _buildAltButton(
              label: "Google",
              icon: Icons.g_mobiledata,
              onTap: onGoogleTap,
            ),
            const SizedBox(width: 15), // 👈 spacing between buttons
            _buildAltButton(
              label: "Apple",
              icon: Icons.apple,
              onTap: onAppleTap,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Already have an account
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Color(0xFF7B7B7B),
                fontSize: 14,
                fontFamily: 'Open Sans',
              ),
            ),
            GestureDetector(
              onTap: onLoginTap,
              child: Text(
                "Signup",
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Open Sans',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAltButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8B4513), width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF8B4513), size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 16,
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
