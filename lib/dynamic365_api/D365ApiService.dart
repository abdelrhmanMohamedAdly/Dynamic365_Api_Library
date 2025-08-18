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

  /// Sends a POST request to create a record in a Dynamics 365 entity.
  ///
  /// Parameters:
  /// - entity: the entity name (e.g., SalesOrderHeaders, SalesOrderLines)
  /// - payload: a map of field names and values to create
  /// - filterByField / filterValue: optional, not usually used with POST
  /// - mainField: optional, the field to return from the response (like salesOrderId)
  ///
  /// Returns:
  /// - the value of mainField if provided and returned by D365
  /// - null if failed or mainField not set

  Future<String?> postEntity(String entity,
      Map<String, dynamic> payload, {
        String? filterByField,
        String? filterValue,
        String? mainField,

        /// like salesOrderId
      }) async {
    final token = await getAccessToken();
    if (token == null) return null;

    final url = (filterByField != null &&
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
      if (mainField != null) {
        final data = jsonDecode(response.body);
        return data[mainField];
      }
      else {
        return null;
      }
    } else {
      print("❌ Failed to post $entity: ${response.statusCode} - ${response
          .body}");
      return null;
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

  /// Fetch dropdown data from a Dynamics 365 entity.
  ///
  /// Parameters:
  /// [entity]         - The target data entity name (e.g., Customers, Items).
  /// [valueField]     - The field name to be used as the unique key (e.g., "CustomerAccount").
  /// [displayField]   - The field name to be shown in the dropdown (e.g., "Name").
  /// [filterByField]  - (Optional) A field name used for filtering results.
  /// [filterValue]    - (Optional) The value to filter by.
  ///
  /// Returns:
  /// A `List<Map<String, String>>` where each map contains:
  ///   - "key"   : the unique identifier of the record.
  ///   - "value" : the display name of the record.
  ///
  /// Notes:
  /// - Removes duplicates by converting the list to a Set, then back to a List.
  /// - Throws an exception if the API request fails.
  /// - Requires a valid access token from `getAccessToken()`.

  Future<List<Map<String, String>>> getDropdownData({
    required String entity,
    required String valueField,
    required String displayField,
    String? filterByField,
    String? filterValue,
  }) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final uri = (filterByField != null &&
        filterByField.isNotEmpty &&
        filterValue != null &&
        filterValue.isNotEmpty)
        ? Uri.parse(
        "$resource/data/$entity?\$filter=$filterByField eq '$filterValue'")
        : Uri.parse("$resource/data/$entity");

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
          '❌ Failed to fetch $entity: ${response.statusCode}\n${response
              .body}',
        );
      }
    } catch (e) {
      print('❗ Exception during getDropdownData: $e');
      rethrow;
    }
  }

}
