import 'dart:convert';
import 'package:http/http.dart' as http;
import 'd365_storage.dart';
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

    // If filterByField not provided, try to get from storage
    filterByField ??= await StorageService.readData("${entity}_filterBy");

    // If still null, save empty string to storage
    if (filterByField == null) {
      filterByField = "";
      await StorageService.saveData("${entity}_filterBy", filterByField);
    }

    // Save entity name in storage
    await StorageService.saveData("${entity}_name", entity);

    final String url = filterByField.isNotEmpty
        ? "$resource/data/$entity?\$filter=$filterByField eq '$filterValue'"
        : "$resource/data/$entity";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["value"];
    }
    return [];
  }

  /// post date to entity
  Future<bool> postEntity(
    String entity,
    Map<String, dynamic> payload, {
    String? filterByField,
    String? filterValue,
  }) async {
    final token = await getAccessToken();
    if (token == null) return false;

    Uri url;
    if (filterByField != null &&
        filterByField.isNotEmpty &&
        filterValue != null &&
        filterValue.isNotEmpty) {
      url = Uri.parse(
        "$resource/data/$entity?\$filter=$filterByField eq '$filterValue'",
      );
    } else {
      url = Uri.parse("$resource/data/$entity");
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(payload),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  /// update data
  Future<bool> updateEntity(
    String entity,
    Map<String, dynamic> payload, {
    String? keyField,
    String? keyValue,
  }) async {
    final token = await getAccessToken();
    if (token == null) return false;

    if (keyField == null || keyValue == null) {
      print("❌ Key field and value are required to update an entity");
      return false;
    }

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

    return response.statusCode == 204 || response.statusCode == 200;
  }
}
