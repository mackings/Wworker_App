import 'package:shared_preferences/shared_preferences.dart';

class InvoiceTemplatePrefs {
  static const _key = "invoice_template_index";

  static Future<int> getTemplateIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<void> setTemplateIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }
}
