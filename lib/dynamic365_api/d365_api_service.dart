import 'dart:convert';
import 'package:http/http.dart' as http;
import 'd365_service_base.dart';

class D365PutService extends D365ServiceBase {
  D365PutService({
    required super.tenantId,
    required super.clientId,
    required super.clientSecret,
    required super.resource,
  });

  /// Get data from entity
  Future<List<dynamic>> getEntityData({
    required String entity,
    String? filterByField,
    String? filterValue,
  }) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final String url = (filterByField != null &&
        filterByField.isNotEmpty &&
        filterValue != null &&
        filterValue.isNotEmpty)
        ? "$resource/data/$entity?\$filter=$filterByField eq '$filterValue'"
        : "$resource/data/$entity";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["value"] ?? [];
    } else {
      print(
          "❌ Failed to get $entity: ${response.statusCode} - ${response.body}");
      return [];
    }
  }

  /// Post data to entity
  Future<bool> postEntity(String entity,
      Map<String, dynamic> payload, {
        String? filterByField,
        String? filterValue,
      }) async {
    final token = await getAccessToken();
    if (token == null) return false;

    final Uri url = (filterByField != null &&
        filterByField.isNotEmpty &&
        filterValue != null &&
        filterValue.isNotEmpty)
        ? Uri.parse(
        "$resource/data/$entity?\$filter=$filterByField eq '$filterValue'")
        : Uri.parse("$resource/data/$entity");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print("❌ Failed to post $entity: ${response.statusCode} - ${response
          .body}");
      return false;
    }
  }

  /// Update data
  Future<bool> updateEntity(String entity,
      Map<String, dynamic> payload, {
        required String keyField,
        required String keyValue,
      }) async {
    final token = await getAccessToken();
    if (token == null) return false;

    final url = Uri.parse("$resource/data/$entity($keyField='$keyValue')");

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return true;
    } else {
      print("❌ Failed to update $entity: ${response.statusCode} - ${response
          .body}");
      return false;
    }
  }
}
