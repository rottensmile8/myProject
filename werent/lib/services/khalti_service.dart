import 'dart:convert';
import 'package:http/http.dart' as http;

class KhaltiService {
  static const String secretKey = "977d3afa16a244c191472f0919b4fd90";

  static const String initiateUrl =
      "https://dev.khalti.com/api/v2/epayment/initiate/";

  static Future<String?> createPayment({
    required int amount, // paisa
    required String orderId,
    required String orderName,
  }) async {
    final response = await http.post(
      Uri.parse(initiateUrl),
      headers: {
        "Authorization": "Key $secretKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "return_url": "https://example.com/payment-success",
        "website_url": "https://example.com",
        "amount": amount,
        "purchase_order_id": orderId,
        "purchase_order_name": orderName,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data["payment_url"];
    } else {
      print("Khalti error: ${response.body}");
      return null;
    }
  }
}