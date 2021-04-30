import 'package:cryptography/cryptography.dart';

class HMAC {
  static Future<List<int>> calcHMAC(List<int> key, List<int> data) async {
    final hmac = Hmac.sha256();
    final mac = await hmac.calculateMac(
      data,
      secretKey: SecretKey(key),
    );
    return Future.value(mac.bytes);
  }

  static Future<bool> validateHMAC(
    List<int> key,
    List<int> data,
    List<int> expectedHMAC,
  ) async {
    if (expectedHMAC.length != 32) {
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
