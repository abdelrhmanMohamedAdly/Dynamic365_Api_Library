import 'dart:convert';
import 'package:http/http.dart' as http;

class D365ServiceBase {
  final String tenantId;
  final String clientId;
  final String clientSecret;
  final String resource;

  D365ServiceBase({
    required this.tenantId,
    required this.clientId,
    required this.clientSecret,
    required this.resource,
  });

  /// Get Access Token
  Future<String?> getAccessToken() async {
    final url = Uri.parse(
      'https://login.microsoftonline.com/$tenantId/oauth2/token',
    );

    final response = await http.post(
      url,
      body: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
        'resource': resource,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['access_token'];
    } else {
      print("❌ Failed to get token: ${response.body}");
      return null;
    }
  }
}
