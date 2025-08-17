import 'dart:convert';
import 'package:http/http.dart' as http;
import 'D365ServiceBase.dart';

class D365ApiService extends D365ServiceBase {
  D365ApiService({
    required super.tenantId,
    required super.clientId,
    required super.clientSecret,
    required super.resource,
  });

  /// Retrieves data from a specified Dynamics 365 entity using an optional filter.
  ///
  /// [entity] - the name of the entity to fetch data from.
  /// [filterByField] & [filterValue] - optional parameters to filter the result set.
  ///
  /// Returns a list of records if the request succeeds, otherwise an empty list.

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

  /// Sends a POST request to create a new record in the specified Dynamics 365 entity.
  ///
  /// [entity] - the name of the target entity.
  /// [payload] - the data to be posted as a new record.
  /// [filterByField] & [filterValue] - optional filter to target a specific record set.
  ///
  /// Returns true if the request succeeds (201/200), otherwise false.

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

  /// Sends a PATCH request to update an existing record in the specified Dynamics 365 entity.
  ///
  /// [entity] - the name of the target entity.
  /// [payload] - the fields and values to update.
  /// [keyField] - the primary key field used to identify the record.
  /// [keyValue] - the value of the key field to locate the record.
  ///
  /// Returns true if the request succeeds (204/200), otherwise false.

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

  /// Retrieves data from any Dynamics 365 entity as a list.
  ///
  /// Supports optional field selection and filtering:
  /// [entity] - the name of the target entity.
  /// [fields] - optional list of fields to select from the entity.
  /// [keyField] & [keyValue] - optional filter to return only matching records.
  ///
  /// Returns a list of records (dynamic objects) or an empty list if the request fails.

  Future<List<dynamic>> getEntityFieldsData({
    required String entity,
    List<String>? fields,
    String? keyField,
    String? keyValue,
  }) async {
    final token = await getAccessToken();
    if (token == null) return [];

    // Build select query if fields are provided
    String selectQuery = '';
    if (fields != null && fields.isNotEmpty) {
      selectQuery = "\$select=${fields.join(',')}";
    }

    // Build filter query if keyField and keyValue are provided
    String filterQuery = '';
    if (keyField != null && keyValue != null) {
      filterQuery = "\$filter=$keyField eq '$keyValue'";
    }

    // Combine select + filter
    String query = '';
    if (selectQuery.isNotEmpty && filterQuery.isNotEmpty) {
      query = "$selectQuery&$filterQuery";
    } else if (selectQuery.isNotEmpty) {
      query = selectQuery;
    } else if (filterQuery.isNotEmpty) {
      query = filterQuery;
    }

    final String url = query.isNotEmpty
        ? "$resource/data/$entity?$query"
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

  /// Fetches generic dropdown data from a given entity in Dynamics 365.
  ///
  /// The function is reusable for any entity by specifying:
  /// [entityName] - the name of the data entity in D365.
  /// [valueField] - the field to be used as the key.
  /// [displayField] - the field to be used as the display text in the dropdown.
  ///
  /// Returns a list of key-value pairs that can be directly bound to a dropdown.

  Future<List<Map<String, String>>> getDropdownData(String token, {
    required String entityName,
    required String valueField,
    required String displayField,
  }) async {
    final uri = Uri.parse("$resource/data/$entityName");

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entities = data['value'] as List;

        return entities
            .map<Map<String, String>>((e) {
          final key = e[valueField]?.toString() ?? '';
          final name = e[displayField]?.toString() ?? '';
          return {"key": key, "value": name};
        })
            .toSet()
            .toList();
      } else {
        throw Exception(
          '❌ Failed to fetch $entityName: ${response.statusCode}\n${response
              .body}',
        );
      }
    } catch (e) {
      print('❗ Exception during getDropdownData: $e');
      rethrow;
    }
  }

}
