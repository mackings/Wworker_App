import 'package:flutter/material.dart';

class ClientsCard extends StatelessWidget {
  final List<String> clientNames;
  final Function(String clientName) onGenerateInvoice;

  const ClientsCard({
    Key? key,
    required this.clientNames,
    required this.onGenerateInvoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFCFCFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              color: const Color(0xFFF5F8F2),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Color(0xFF8B4513)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ), // Increased padding
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Makes client name take available space
                  child: Text(
                    'Client Name',
                    style: TextStyle(
                      color: Color(0xFF8B4513),
                      fontSize: 14, // Slightly larger font
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w500, // Slightly bolder
                    ),
                  ),
                ),
                Text(
                  'Invoice',
                  style: TextStyle(
                    color: Color(0xFF8B4513),
                    fontSize: 14, // Slightly larger font
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w500, // Slightly bolder
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🧾 Client Rows - Responsive
          ...clientNames.map((clientName) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 1,
                    color: Color(0xFFD3D3D3), // Surface-Overlay
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ), // Increased padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Client Name - Expanded to take available space
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        color: Color(0xFF302E2E), // Typography-Subtext
                        fontSize: 12, // Slightly larger
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long names
                    ),
                  ),

                  const SizedBox(width: 16), // Increased spacing
                  // Generate Invoice Button
                  InkWell(
                    onTap: () => onGenerateInvoice(clientName),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ), // Increased padding
                      decoration: ShapeDecoration(
                        color: const Color(0xFFB7835E), // Brown-Brown-300
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Generate Invoice',
                        style: TextStyle(
                          color: Color(0xFFFEFEFE),
                          fontSize: 12,
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
