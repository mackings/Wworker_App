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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DED6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  title.toLowerCase().contains('company')
                      ? Icons.business_outlined
                      : Icons.person_outline_rounded,
                  color: const Color(0xFF8B4513),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF211D1A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Column(
            children: [
              _buildRow('Name', contact.name),
              _buildRow('Address', contact.address),
              _buildRow('Nearest Bus/Stop', contact.nearestBusStop),
              _buildRow('Phone No', contact.phone),
              _buildRow('Email', contact.email),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DED6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 106,
            child: Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF756A61),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: GoogleFonts.openSans(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF211D1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
