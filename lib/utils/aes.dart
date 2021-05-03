import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cso_client_flutter/message/define.dart';

class AES {
  static Future<SecretBox> encrypt(
    List<int> key,
    List<int> data,
    List<int> aad,
  ) async {
    final random = Random.secure();
    final aes = AesGcm.with256bits(nonceLength: Constant.lengthIV);
    final iv = List<int>.generate(
      Constant.lengthIV,
      (index) => random.nextInt(256),
    );
    return aes.encrypt(
      data,
      secretKey: SecretKey(key),
      nonce: iv,
      aad: aad,
    );
  }

  static Future<List<int>> decrypt(
    List<int> key,
    List<int> iv,
    List<int> authenTag,
    List<int> data,
    List<int> aad,
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
    return msg;
  }
}
