# D365 API Client for Dart

[![Pub Version](https://img.shields.io/pub/v/dynamic365_api?style=for-the-badge)](https://pub.dev/packages/dynamic365_api)
[![GitHub Stars](https://img.shields.io/github/stars/abdelrhmanMohamedAdly/Dynamic365_Api_Library?style=social)](https://github.com/abdelrhmanMohamedAdly/Dynamic365_Api_Library)

A powerful Dart package for seamless integration with **Microsoft Dynamics 365 Web API**.  
✅ Automatic OAuth 2.0 Authentication  
✅ Full CRUD Operations  
✅ Optimized for Flutter & Dart

---

## 📦 **Installation**

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dynamic365_api: ^1.0.0
Then run:
flutter pub get

🚀 Quick Start

1. Import the Package
dart
import 'package:dynamic365_api/dynamic365_api/D365ApiService.dart';

2. Initialize the Service
dart
final d365 = D365ApiService(
  tenantId: 'your_tenant_id',
  clientId: 'your_client_id',
  clientSecret: 'your_client_secret',
  resource: 'https://your_org.crm.dynamics.com',
);

3. Use Core Features

// Fetch data
final accounts = await d365.getEntityData(entity: 'accounts');

// Create record
await d365.postEntity('contacts', {
  'firstname': 'John',
  'lastname': 'Doe',
});

// Update record
await d365.updateEntity(
  'accounts',
  {'name': 'New Name'},
  keyField: 'accountid',
  keyValue: '00000000-0000-0000-0000-000000000000',
);

✨ Key Features
Feature	Method	Description
Authentication	getAccessToken()  Auto-refreshing OAuth 2.0 tokens
Read Data	    getEntityData()	  Fetch with optional filtering
Create Data	    postEntity()	  Add new records
Update Data	    updateEntity()	  Modify existing records
Dropdown Data	getDropdownData() Key-value pairs for UI components

⚙️ Advanced Usage
Field Selection
dart
final minimalData = await d365.getEntityFieldsData(
  entity: 'contacts',
  fields: ['fullname', 'email'],
);

Error Handling
dart
try {
  await d365.getEntityData(entity: 'invoices');
} catch (e) {
  print('Error: ${e.toString()}');
  // Handle specific error scenarios
}

📜 License
This project is licensed under the MIT License.
See LICENSE for details.
MIT License - See [LICENSE](https://github.com/abdelrhmanMohamedAdly/Dynamic365_Api_Library/blob/main/LICENSE) for details.