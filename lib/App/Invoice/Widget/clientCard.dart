import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientsCard extends StatelessWidget {
  final List<String> clientNames;
  final Function(String clientName) onGenerateInvoice;

  const ClientsCard({
    super.key,
    required this.clientNames,
    required this.onGenerateInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: clientNames.map((clientName) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8DED6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF8B4513),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.openSans(
                    color: const Color(0xFF211D1A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => onGenerateInvoice(clientName),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Invoice'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B4513),
                  backgroundColor: const Color(0xFFFFF3E8),
                  textStyle: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
