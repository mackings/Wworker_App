import 'package:shared_preferences/shared_preferences.dart';

class InvoiceBankPrefs {
  static const _bankNameKey = "invoice_bank_name";
  static const _accountNameKey = "invoice_account_name";
  static const _accountNumberKey = "invoice_account_number";
  static const _bankCodeKey = "invoice_bank_code";

  static Future<Map<String, String>> getBankDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "bankName": prefs.getString(_bankNameKey) ?? "Your Bank",
      "accountName": prefs.getString(_accountNameKey) ?? "Account Name",
      "accountNumber": prefs.getString(_accountNumberKey) ?? "0000000000",
      "bankCode": prefs.getString(_bankCodeKey) ?? "000000",
    };
  }

  static Future<void> saveBankDetails({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String bankCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bankNameKey, bankName);
    await prefs.setString(_accountNameKey, accountName);
    await prefs.setString(_accountNumberKey, accountNumber);
    await prefs.setString(_bankCodeKey, bankCode);
  }
}
