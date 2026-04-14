import '../models/password_secret.dart';
import '../models/user_profile.dart';
import 'appwrite_provider.dart';
import 'backend_config.dart';
import 'encryption_service.dart';
import 'hardware_tap_listener.dart';
import 'repositories/profile_repository.dart';
import 'repositories/secret_repository.dart';

class BackendSessionManager {
  final BackendConfig config;
  final ProfileLookup profiles;
  final SecretStore secrets;
  final HardwareTapPort hardware;

  String? _activeRfidUid;

  BackendSessionManager._({
    required this.config,
    required this.profiles,
    required this.secrets,
    required this.hardware,
  });

  factory BackendSessionManager.withDependencies({
    required BackendConfig config,
    required ProfileLookup profiles,
    required SecretStore secrets,
    required HardwareTapPort hardware,
  }) {
    return BackendSessionManager._(
      config: config,
      profiles: profiles,
      secrets: secrets,
      hardware: hardware,
    );
  }

  factory BackendSessionManager(BackendConfig config) {
    final AppwriteProvider appwrite = AppwriteProvider(config);
    final EncryptionService encryption = EncryptionService(
      salt: config.encryptionSalt,
    );

    return BackendSessionManager._(
      config: config,
      profiles: ProfileRepository(config: config, appwrite: appwrite),
      secrets: SecretRepository(
        config: config,
        appwrite: appwrite,
        encryption: encryption,
      ),
      hardware: HardwareTapListener(config: config, appwrite: appwrite),
    );
  }

  bool get isConfigured => config.isConfigured;

  Future<void> _performLogin(String rfidUid, {
    required Future<void> Function(UserProfile profile, List<PasswordSecret> secrets)
        onLogin,
  }) async {
    final UserProfile? profile = await profiles.findProfileByRfidUid(rfidUid);
    if (profile == null) {
      return;
    }

    final List<PasswordSecret> userSecrets =
        await secrets.fetchSecretsForRfidUid(rfidUid: rfidUid);

    _activeRfidUid = rfidUid;

    await onLogin(profile, userSecrets);
  }

  Future<void> startHardwareListener({
    required Future<void> Function(UserProfile profile, List<PasswordSecret> secrets)
        onLogin,
    required Future<void> Function() onLogout,
  }) async {
    if (!isConfigured) {
      return;
    }

    hardware.start(
      onActiveTap: (String rfidUid) async {
        await _performLogin(rfidUid, onLogin: onLogin);
      },
      onInactiveTap: () async {
        _activeRfidUid = null;
        await onLogout();
      },
    );
  }

  Future<void> createSecret({
    required String serviceName,
    required String username,
    required String plainPassword,
    required String category,
  }) async {
    final String? rfidUid = _activeRfidUid;
    if (rfidUid == null) {
      throw StateError('No active RFID session');
    }

    await secrets.createSecret(
      serviceName: serviceName,
      username: username,
      plainPassword: plainPassword,
      rfidUid: rfidUid,
      category: category,
    );
  }

  Future<void> updateSecret({
    required String secretId,
    required String serviceName,
    required String username,
    required String plainPassword,
    required String category,
  }) async {
    final String? rfidUid = _activeRfidUid;
    if (rfidUid == null) {
      throw StateError('No active RFID session');
    }

    await secrets.updateSecret(
      secretId: secretId,
      serviceName: serviceName,
      username: username,
      plainPassword: plainPassword,
      rfidUid: rfidUid,
      category: category,
    );
  }

  Future<void> deleteSecret({
    required String secretId,
  }) async {
    final String? rfidUid = _activeRfidUid;
    if (rfidUid == null) {
      throw StateError('No active RFID session');
    }

    await secrets.deleteSecret(secretId: secretId, rfidUid: rfidUid);
  }

  Future<List<PasswordSecret>> fetchActiveSecrets() async {
    final String? rfidUid = _activeRfidUid;
    if (rfidUid == null) {
      return <PasswordSecret>[];
    }

    return secrets.fetchSecretsForRfidUid(rfidUid: rfidUid);
  }

  Future<void> demoLogin({
    required Future<void> Function(UserProfile profile, List<PasswordSecret> secrets)
        onLogin,
  }) async {
    if (!isConfigured) {
      return;
    }
    await _performLogin('00000000', onLogin: onLogin);
  }

  void dispose() {
    hardware.stop();
  }
}

abstract class ProfileLookup {
  Future<UserProfile?> findProfileByRfidUid(String rfidUid);
}

abstract class SecretStore {
  Future<void> createSecret({
    required String serviceName,
    required String username,
    required String plainPassword,
    required String rfidUid,
    required String category,
  });

  Future<void> updateSecret({
    required String secretId,
    required String serviceName,
    required String username,
    required String plainPassword,
    required String rfidUid,
    required String category,
  });

  Future<void> deleteSecret({
    required String secretId,
    required String rfidUid,
  });

  Future<List<PasswordSecret>> fetchSecretsForRfidUid({
    required String rfidUid,
  });
}

abstract class HardwareTapPort {
  void start({
    required Future<void> Function(String rfidUid) onActiveTap,
    required Future<void> Function() onInactiveTap,
  });

  void stop();
}
