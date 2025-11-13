import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wworker/App/Quotation/Api/ClientQuotation.dart';
import 'package:wworker/App/Quotation/Model/ClientQmodel.dart';

final quotationProvider =
    StateNotifierProvider<QuotationNotifier, AsyncValue<List<Quotation>>>(
      (ref) => QuotationNotifier(ref),
    );

class QuotationNotifier extends StateNotifier<AsyncValue<List<Quotation>>> {
  final Ref ref;
  final ClientQuotationService _service = ClientQuotationService();
  bool _hasFetched = false; // ✅ prevent multiple fetches

  QuotationNotifier(this.ref) : super(const AsyncLoading()) {
    _fetchOnce();
  }

  void _fetchOnce() {
    if (!_hasFetched) {
      fetchQuotations();
      _hasFetched = true;
    }
  }

  /// Fetch all quotations from the API
  Future<void> fetchQuotations() async {
    try {
      state = const AsyncLoading();
      final response = await _service.getAllQuotations();

      if (response["success"] == true) {
        final result = QuotationResponse.fromJson(response);
        state = AsyncData(result.data);
      } else {
        state = AsyncError(
          response["message"] ?? "Failed to load quotations",
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void deleteQuotation(String id) {
    debugPrint("❌ Quotation deletion is disabled.");
  }
}
