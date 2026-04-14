import 'package:appwrite/appwrite.dart';

import 'backend_config.dart';

class AppwriteProvider {
  final Client client;
  final Account account;
  final Databases databases;
  final Realtime realtime;

  AppwriteProvider._({
    required this.client,
    required this.account,
    required this.databases,
    required this.realtime,
  });

  factory AppwriteProvider(BackendConfig config) {
    final Client client = Client()
        .setEndpoint(config.endpoint)
        .setProject(config.projectId);

    return AppwriteProvider._(
      client: client,
      account: Account(client),
      databases: Databases(client),
      realtime: Realtime(client),
    );
  }
}
