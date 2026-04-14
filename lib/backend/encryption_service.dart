import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  final String salt;

  const EncryptionService({required this.salt});

  encrypt.Key _deriveKey({
    required String rfidUid,
    required String accountId,
  }) {
    final String seed = '$rfidUid:$accountId:$salt';
    final List<int> keyBytes = sha256.convert(utf8.encode(seed)).bytes;
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  String encryptPassword({
    required String plainText,
    required String rfidUid,
    required String accountId,
  }) {
    final encrypt.Key key = _deriveKey(rfidUid: rfidUid, accountId: accountId);
    final encrypt.IV iv = encrypt.IV.fromSecureRandom(16);
    final encrypt.Encrypter encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final encrypt.Encrypted encrypted = encrypter.encrypt(plainText, iv: iv);
    final String ivEncoded = base64UrlEncode(iv.bytes);
    return '$ivEncoded:${encrypted.base64}';
  }

  String decryptPassword({
    required String encryptedText,
    required String rfidUid,
    required String accountId,
  }) {
    final List<String> parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted payload format');
    }

    final encrypt.Key key = _deriveKey(rfidUid: rfidUid, accountId: accountId);
    final encrypt.IV iv = encrypt.IV(base64Url.decode(parts[0]));
    final encrypt.Encrypted payload = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypt.Encrypter encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    return encrypter.decrypt(payload, iv: iv);
  }
}
