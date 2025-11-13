import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactInfo {
  final String name;
  final String address;
  final String nearestBusStop;
  final String phone;
  final String email;

  ContactInfo({
    required this.name,
    required this.address,
    required this.nearestBusStop,
    required this.phone,
    required this.email,
  });
}

class QuotationInfo extends StatelessWidget {
  final ContactInfo contact;
  final String title;

  const QuotationInfo({
    super.key,
    required this.contact,
    this.title = "Client’s Information",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF302E2E),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: const Color(0xFFFCFCFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Column(
              children: [
                _buildRow('Name', contact.name),
                _buildRow('Address', contact.address),
                _buildRow('Nearest Bus/Stop', contact.nearestBusStop),
                _buildRow('Phone No', contact.phone),
                _buildRow('Email', contact.email),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF121111),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF302E2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
