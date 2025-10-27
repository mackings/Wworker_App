import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Widget/QGlancecard.dart';

class QuotationSummary extends ConsumerStatefulWidget {
  const QuotationSummary({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QuotationSummaryState();
}

class _QuotationSummaryState extends ConsumerState<QuotationSummary> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(
        child: Column(
          children: [

          QuoteGlanceCard(
  imageUrl: "https://placehold.co/263x200",
  productName: "Dining Table",
  bomNo: "1001",
  description: "6-seater dining set",
  costPrice: 923500,
  sellingPrice: 1200000,
  quantity: 10,
  onIncrease: () => print("Increase quantity"),
  onDecrease: () => print("Decrease quantity"),
  onDelete: () => print("Item deleted"),
),


          ],
        ),
      )),
    );
  }
}