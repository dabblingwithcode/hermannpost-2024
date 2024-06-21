import 'dart:io';

import 'package:encrypt/encrypt.dart' as enc;

import 'package:path_provider/path_provider.dart';

final customEncrypter = CustomEncrypter();

class CustomEncrypter {
  String encrypt(
      {required String nonEncryptedString,
      required String keyUtf8,
      required String ivUtf8}) {
    final key = enc.Key.fromUtf8(keyUtf8);
    final iv = enc.IV.fromUtf8(ivUtf8);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encryptedString =
        encrypter.encrypt(nonEncryptedString, iv: iv).base64;
    return encryptedString;
  }

  String decrypt({
    required String encryptedString,
    required String keyUtf8,
    required String ivUtf8,
  }) {
    if (encryptedString.isEmpty) {
      return '';
    }
    final key = enc.Key.fromUtf8(keyUtf8);
    final iv = enc.IV.fromUtf8(ivUtf8);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final thisEncryptedString = enc.Encrypted.fromBase64(encryptedString);
    final decryptedString = encrypter.decrypt(thisEncryptedString, iv: iv);
    return decryptedString;
  }

  Future<File> encryptFile({
    required File file,
    required String keyUtf8,
    required String ivUtf8,
  }) async {
    final key = enc.Key.fromUtf8(keyUtf8);
    final iv = enc.IV.fromUtf8(ivUtf8);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final List<int> fileBytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
    final Directory tempDir = await getTemporaryDirectory();
    final Uri uri = Uri.parse(file.path);
    final String extension = uri.pathSegments.last.split('.').last;
    final File tempFile = File('${tempDir.path}/encrypted_file.$extension');
    await tempFile.writeAsBytes(encrypted.bytes);
    return tempFile;
  }
}
