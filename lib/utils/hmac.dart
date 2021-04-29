import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class HMAC {
  static Future<Uint8List> calcHMAC(Uint8List key, Uint8List data) async {
    final hmac = Hmac.sha256();
    final mac = await hmac.calculateMac(
      data,
      secretKey: SecretKey(key),
    );
    return Future.value(Uint8List.fromList(mac.bytes));
  }

  static Future<bool> validateHMAC(
    Uint8List key,
    Uint8List data,
    Uint8List expectedHMAC,
  ) async {
    if (expectedHMAC.lengthInBytes != 32) {
      return Future.value(false);
    }
    final hmac = await HMAC.calcHMAC(key, data);
    for (var idx = 0; idx < 32; ++idx) {
      if (hmac[idx] != expectedHMAC[idx]) {
        return false;
      }
    }
    return Future.value(true);
  }
}
