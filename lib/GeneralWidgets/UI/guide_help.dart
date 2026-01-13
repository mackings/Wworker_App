import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _guideKey = "guideEnabled";




final guideProvider = StateNotifierProvider<GuideNotifier, bool>((ref) {
  return GuideNotifier();
});

class GuideNotifier extends StateNotifier<bool> {
  GuideNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_guideKey);
    if (value != null) state = value;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guideKey, value);
  }
}

void showGuideSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it"),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class GuideHelpIcon extends ConsumerWidget {
  final String title;
  final String message;
  final IconData icon;

  const GuideHelpIcon({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.help_outline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(guideProvider);
    if (!enabled) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: () => showGuideSheet(
        context,
        title: title,
        message: message,
      ),
      tooltip: "Help",
    );
  }
}
