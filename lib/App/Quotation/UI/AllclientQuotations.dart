import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Quotation/Providers/QuotationProvider.dart';
import 'package:wworker/App/Quotation/Widget/ClientQCard.dart';
import 'package:wworker/Constant/urls.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';

class AllClienrQuotations extends ConsumerWidget {
  const AllClienrQuotations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotationsState = ref.watch(quotationProvider);
    final notifier = ref.read(quotationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(title: "Quotation",),
      ),
      body: quotationsState.when(
        data: (quotations) {
          if (quotations.isEmpty) {
            return const Center(child: Text('No quotations found.'));
          }

          return RefreshIndicator(
            onRefresh: () => notifier.fetchQuotations(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: quotations.length,
              itemBuilder: (context, index) {
                final quotation = quotations[index];
                final firstItem = quotation.items.isNotEmpty
                    ? quotation.items.first
                    : null;

                return ClientQuotationCard(
                  quotation: {
                    'clientName': quotation.clientName,
                    'phoneNumber': quotation.phoneNumber,
                    'description': quotation.description,
                    'finalTotal': quotation.finalTotal,
                    'status': quotation.status,
                    'createdAt': quotation.createdAt.toIso8601String(),
                    'quotationNumber': quotation.quotationNumber,
                    'items': firstItem != null
                        ? [
                            {
                              'productName': quotation.service.product,
                              'woodType': firstItem.woodType ?? 'N/A',
                              'image': firstItem.image.isNotEmpty
                                  ? firstItem.image
                                  : Urls.woodImg,
                            }
                          ]
                        : [],
                  },
                  onDelete: () => notifier.deleteQuotation(quotation.id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load quotations: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => notifier.fetchQuotations(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
