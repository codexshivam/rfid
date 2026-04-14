import 'appwrite_provider.dart';
import 'backend_config.dart';
import 'backend_session_manager.dart';

class HardwareTapListener implements HardwareTapPort {
  final BackendConfig config;
  final AppwriteProvider appwrite;

  dynamic _subscription;

  HardwareTapListener({required this.config, required this.appwrite});

  @override
  void start({
    required Future<void> Function(String rfidUid) onActiveTap,
    required Future<void> Function() onInactiveTap,
  }) {
    final String channel = config.sessionsRealtimeChannel;
    if (channel.isEmpty) {
      return;
    }

    _subscription = appwrite.realtime.subscribe(<String>[channel]);
    _subscription?.stream.listen((dynamic event) async {
      final Map<String, dynamic> payload =
          Map<String, dynamic>.from(event.payload as Map);
      final bool isActive = payload['is_active'] == true;
      final String rfidUid = (payload['current_uid'] ?? '').toString();

      if (isActive && rfidUid.isNotEmpty) {
        await onActiveTap(rfidUid);
      } else {
        await onInactiveTap();
      }
    });
  }

  @override
  void stop() {
    _subscription?.close();
    _subscription = null;
  }
}
