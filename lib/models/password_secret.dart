class PasswordSecret {
  final String id;
  final String service;
  final String username;
  final String password;
  final String lastModified;
  final String category;

  PasswordSecret(
    this.service,
    this.username,
    this.lastModified, {
    this.id = '',
    this.password = '',
    this.category = 'Others',
  });
}
