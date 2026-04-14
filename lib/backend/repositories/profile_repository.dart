import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import '../../models/user_profile.dart';
import '../backend_config.dart';
import '../appwrite_provider.dart';
import '../backend_session_manager.dart';

class ProfileRepository implements ProfileLookup {
  static const List<String> _uidKeys = <String>[
    'rfid_uid',
    'rfidUid',
    'uid',
    'user_id',
    'current_uid',
  ];

  final BackendConfig config;
  final AppwriteProvider appwrite;

  const ProfileRepository({required this.config, required this.appwrite});

  Future<models.Document?> findProfileDocumentByRfidUid(String rfidUid) async {
    final models.DocumentList list = await _listByUid(rfidUid);

    if (list.documents.isEmpty) {
      return null;
    }
    return list.documents.first;
  }

  Future<models.DocumentList> _listByUid(String rfidUid) async {
    for (final String key in _uidKeys) {
      try {
        final models.DocumentList list = await appwrite.databases.listDocuments(
          databaseId: config.databaseId,
          collectionId: config.profilesCollectionId,
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
      collectionId: config.profilesCollectionId,
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

  @override
  Future<UserProfile?> findProfileByRfidUid(String rfidUid) async {
    final models.Document? doc = await findProfileDocumentByRfidUid(rfidUid);
    if (doc == null) {
      return null;
    }

    final Map<String, dynamic> data = doc.data;
    return UserProfile(
      name: (data['name'] ?? '').toString(),
      orgUnit: (data['orgUnit'] ?? '').toString(),
      lastLogin: _resolveLastLogin(data, doc.$updatedAt),
    );
  }

  String _resolveLastLogin(Map<String, dynamic> data, String updatedAt) {
    final String explicitLastLoginRaw = (data['lastLogin'] ?? data['last_login'] ?? '')
        .toString()
        .trim();
    DateTime? timestamp = DateTime.tryParse(explicitLastLoginRaw);
    timestamp ??= DateTime.tryParse(updatedAt);
    if (timestamp == null) {
      return explicitLastLoginRaw;
    }

    final DateTime localTime = timestamp.toLocal();
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const List<String> weekdays = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final int hour12 = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
    final String minute = localTime.minute.toString().padLeft(2, '0');
    final String meridiem = localTime.hour >= 12 ? 'PM' : 'AM';

    return '${weekdays[localTime.weekday - 1]}, '
        '${months[localTime.month - 1]} ${localTime.day}, ${localTime.year} '
        '$hour12:$minute $meridiem';
  }
}
