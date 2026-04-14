import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import '../../models/password_secret.dart';
import '../appwrite_provider.dart';
import '../backend_config.dart';
import '../encryption_service.dart';
import '../backend_session_manager.dart';

class SecretRepository implements SecretStore {
  static const List<String> _uidKeys = <String>[
    'rfid_uid',
    'rfidUid',
    'uid',
    'user_id',
    'current_uid',
  ];

  final BackendConfig config;
  final AppwriteProvider appwrite;
  final EncryptionService encryption;

  const SecretRepository({
    required this.config,
    required this.appwrite,
    required this.encryption,
  });

  String _sanitizeSecretId(String secretId) {
    return secretId.trim();
  }

  @override
  Future<void> createSecret({
    required String serviceName,
    required String username,
    required String plainPassword,
    required String rfidUid,
    required String category,
  }) async {
    const String guestAccountMarker = 'guest_access';
    final String encryptedPassword = encryption.encryptPassword(
      plainText: plainPassword,
      rfidUid: rfidUid,
      accountId: guestAccountMarker,
    );

    await appwrite.databases.createDocument(
      databaseId: config.databaseId,
      collectionId: config.secretsCollectionId,
      documentId: ID.unique(),
      data: <String, dynamic>{
        'service_name': serviceName,
        'username': username,
        'password': encryptedPassword,
        'category': _normalizeCategory(category),
        'user_id': guestAccountMarker,
        'rfid_uid': rfidUid,
      },
      permissions: <String>[
        Permission.read(Role.any()),
        Permission.update(Role.any()),
        Permission.delete(Role.any()),
      ],
    );
  }

  @override
  Future<void> updateSecret({
    required String secretId,
    required String serviceName,
    required String username,
    required String plainPassword,
    required String rfidUid,
    required String category,
  }) async {
    const String guestAccountMarker = 'guest_access';
    final String documentId = _sanitizeSecretId(secretId);
    if (documentId.isEmpty) {
      throw StateError('Missing secret id');
    }

    final Map<String, dynamic> updateData = <String, dynamic>{
      'service_name': serviceName,
      'username': username,
      'category': _normalizeCategory(category),
    };

    if (plainPassword.trim().isNotEmpty) {
      updateData['password'] = encryption.encryptPassword(
        plainText: plainPassword,
        rfidUid: rfidUid,
        accountId: guestAccountMarker,
      );
    }

    await appwrite.databases.updateDocument(
      databaseId: config.databaseId,
      collectionId: config.secretsCollectionId,
      documentId: documentId,
      data: updateData,
    );
  }

  @override
  Future<void> deleteSecret({
    required String secretId,
    required String rfidUid,
  }) async {
    final String documentId = _sanitizeSecretId(secretId);
    if (documentId.isEmpty) {
      throw StateError('Missing secret id');
    }

    await appwrite.databases.deleteDocument(
      databaseId: config.databaseId,
      collectionId: config.secretsCollectionId,
      documentId: documentId,
    );
  }

  @override
  Future<List<PasswordSecret>> fetchSecretsForRfidUid({
    required String rfidUid,
  }) async {
    final models.DocumentList list = await _listByUid(rfidUid);

    return list.documents.map((models.Document doc) {
      final Map<String, dynamic> data = doc.data;
      final String encryptedPassword = (data['password'] ?? '').toString();
      String decryptedPassword = '';

      // Decryption is attempted to validate key/card pairing. UI currently
      // keeps masked values, but this verifies that data is decryptable.
      if (encryptedPassword.isNotEmpty) {
        try {
          decryptedPassword = encryption.decryptPassword(
            encryptedText: encryptedPassword,
            rfidUid: rfidUid,
            accountId: 'guest_access',
          );
        } catch (_) {
          // Keep returning metadata even if payload cannot be decrypted yet.
        }
      }

      final DateTime updatedAt = DateTime.tryParse(doc.$updatedAt) ?? DateTime.now();
      final String label = _formatDate(updatedAt);

      return PasswordSecret(
        (data['service_name'] ?? '').toString(),
        (data['username'] ?? '').toString(),
        label,
        id: doc.$id,
        password: decryptedPassword,
        category: _normalizeCategory(
          (data['category'] ?? data['secret_category'] ?? '').toString(),
          serviceName: (data['service_name'] ?? '').toString(),
        ),
      );
    }).toList();
  }

  Future<models.DocumentList> _listByUid(String rfidUid) async {
    for (final String key in _uidKeys) {
      try {
        final models.DocumentList list = await appwrite.databases.listDocuments(
          databaseId: config.databaseId,
          collectionId: config.secretsCollectionId,
          queries: <String>[Query.equal(key, rfidUid)],
        );
        return list;
      } on AppwriteException catch (error) {
        if (!_isMissingAttribute(error)) {
          rethrow;
        }
      }
    }

    final models.DocumentList all = await appwrite.databases.listDocuments(
      databaseId: config.databaseId,
      collectionId: config.secretsCollectionId,
    );

    final List<models.Document> filtered = all.documents.where((models.Document doc) {
      final Map<String, dynamic> data = doc.data;
      return _uidKeys.any((String key) => data[key]?.toString() == rfidUid);
    }).toList();

    return models.DocumentList(total: filtered.length, documents: filtered);
  }

  bool _isMissingAttribute(AppwriteException error) {
    final String type = error.type ?? '';
    final String message = error.message ?? '';
    return error.code == 400 &&
        (type.contains('general_query_invalid') ||
            message.contains('Attribute not found in schema'));
  }

  String _normalizeCategory(String raw, {String serviceName = ''}) {
    final String value = raw.trim().toLowerCase();
    if (value == 'personal') {
      return 'Personal';
    }
    if (value == 'work') {
      return 'Work';
    }
    if (value == 'others' || value == 'other') {
      return 'Others';
    }

    final String serviceLower = serviceName.trim().toLowerCase();
    if (serviceLower.contains('aws') ||
        serviceLower.contains('workspace') ||
        serviceLower.contains('console')) {
      return 'Work';
    }
    if (serviceLower.isNotEmpty) {
      return 'Personal';
    }
    return 'Others';
  }

  String _formatDate(DateTime value) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}
