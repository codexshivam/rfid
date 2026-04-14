import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  final String endpoint;
  final String projectId;
  final String databaseId;
  final String profilesCollectionId;
  final String secretsCollectionId;
  final String sessionsCollectionId;
  final String deviceDocumentId;
  final String encryptionSalt;

  const BackendConfig({
    required this.endpoint,
    required this.projectId,
    required this.databaseId,
    required this.profilesCollectionId,
    required this.secretsCollectionId,
    required this.sessionsCollectionId,
    required this.deviceDocumentId,
    required this.encryptionSalt,
  });

  static String _envValue(String key, {String fallback = ''}) {
    try {
      return dotenv.env[key] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  bool get isConfigured {
    return endpoint.isNotEmpty &&
        projectId.isNotEmpty &&
        databaseId.isNotEmpty &&
        profilesCollectionId.isNotEmpty &&
        secretsCollectionId.isNotEmpty;
  }

  String get sessionsRealtimeChannel {
    if (sessionsCollectionId.isEmpty || deviceDocumentId.isEmpty) {
      return '';
    }
    return 'databases.$databaseId.collections.$sessionsCollectionId.documents.$deviceDocumentId';
  }

  static BackendConfig fromEnv() {
    return BackendConfig(
      endpoint: _envValue('APPWRITE_ENDPOINT'),
      projectId: _envValue('APPWRITE_PROJECT_ID'),
      databaseId: _envValue('APPWRITE_DATABASE_ID'),
      profilesCollectionId: _envValue('APPWRITE_PROFILES_COLLECTION_ID'),
      secretsCollectionId: _envValue('APPWRITE_SECRETS_COLLECTION_ID'),
      sessionsCollectionId: _envValue('APPWRITE_SESSIONS_COLLECTION_ID'),
      deviceDocumentId: _envValue('APPWRITE_DEVICE_DOCUMENT_ID'),
      encryptionSalt: _envValue(
        'APP_ENCRYPTION_SALT',
        fallback: 'rfid-project-default-salt',
      ),
    );
  }
}
