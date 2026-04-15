import 'dart:async';

import 'appwrite_provider.dart';
import 'backend_config.dart';
import 'backend_session_manager.dart';

class HardwareTapListener implements HardwareTapPort {
  static const Duration _pollInterval = Duration(seconds: 1);

  final BackendConfig config;
  final AppwriteProvider appwrite;

  dynamic _subscription;
  StreamSubscription<dynamic>? _streamSubscription;
  Timer? _pollTimer;
  bool? _lastIsActive;
  String _lastUid = '';
  bool _isHandling = false;

  HardwareTapListener({required this.config, required this.appwrite});

  @override
  void start({
    required Future<void> Function(String rfidUid) onActiveTap,
    required Future<void> Function() onInactiveTap,
  }) {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;

    final String channel = config.sessionsRealtimeChannel;
    if (channel.isNotEmpty) {
      _subscription = appwrite.realtime.subscribe(<String>[channel]);
      _streamSubscription = _subscription?.stream.listen((dynamic event) async {
        await _handlePayload(
          _payloadFromEvent(event),
          onActiveTap: onActiveTap,
          onInactiveTap: onInactiveTap,
        );
      });
    }

    if (config.sessionsCollectionId.isNotEmpty &&
        config.deviceDocumentId.isNotEmpty) {
      _pollTimer = Timer.periodic(_pollInterval, (_) async {
        final Map<String, dynamic>? payload = await _fetchSessionPayload();
        if (payload == null) {
          return;
        }
        await _handlePayload(
          payload,
          onActiveTap: onActiveTap,
          onInactiveTap: onInactiveTap,
        );
      });
    }
  }

  @override
  void stop() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _subscription?.close();
    _subscription = null;
    _lastIsActive = null;
    _lastUid = '';
    _isHandling = false;
  }

  Future<Map<String, dynamic>?> _fetchSessionPayload() async {
    try {
      final dynamic document = await appwrite.databases.getDocument(
        databaseId: config.databaseId,
        collectionId: config.sessionsCollectionId,
        documentId: config.deviceDocumentId,
      );
      final dynamic data = document?.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handlePayload(
    Map<String, dynamic> payload, {
    required Future<void> Function(String rfidUid) onActiveTap,
    required Future<void> Function() onInactiveTap,
  }) async {
    if (_isHandling) {
      return;
    }

    final bool isActive = _readBool(payload['is_active']);
    final String rfidUid = _readUid(payload);
    final bool hasStateChanged =
        _lastIsActive != isActive || _lastUid != rfidUid;
    if (!hasStateChanged) {
      return;
    }

    _isHandling = true;
    try {
      _lastIsActive = isActive;
      _lastUid = rfidUid;

      if (isActive && rfidUid.isNotEmpty) {
        await onActiveTap(rfidUid);
      } else {
        await onInactiveTap();
      }
    } finally {
      _isHandling = false;
    }
  }

  Map<String, dynamic> _payloadFromEvent(dynamic event) {
    final dynamic raw = event?.payload;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  String _readUid(Map<String, dynamic> payload) {
    return (payload['current_uid'] ??
            payload['rfid_uid'] ??
            payload['rfidUid'] ??
            payload['uid'] ??
            payload['user_id'] ??
            '')
        .toString()
        .trim();
  }
}
