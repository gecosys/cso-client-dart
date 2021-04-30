import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class AES {
  static Future<SecretBox> encrypt(
    Uint8List key,
    Uint8List data,
    Uint8List aad,
  ) async {
    final aes = AesGcm.with256bits(nonceLength: 12);
    final iv = AES._randomUint8List(12);
    return aes.encrypt(
      data,
      secretKey: SecretKey(key),
      nonce: iv,
      aad: aad,
    );
  }

  static Future<Uint8List> decrypt(
    Uint8List key,
    Uint8List iv,
    Uint8List authenTag,
    Uint8List data,
    Uint8List aad,
  ) async {
    final aes = AesGcm.with256bits(nonceLength: 12);
    final msg = await aes.decrypt(
      SecretBox(
        data,
        nonce: iv,
        mac: Mac(authenTag),
      ),
      secretKey: SecretKey(key),
      aad: aad,
    );
    return Future.value(Uint8List.fromList(msg));
  }

  static Uint8List _randomUint8List(int size) {
    final random = Random.secure();
    final buffer = Uint8List(size);
    for (var i = 0; i < size; ++i) {
      buffer[i] = random.nextInt(256);
    }
    return buffer;
  }
}
