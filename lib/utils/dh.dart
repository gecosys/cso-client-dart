import 'dart:math';

import 'package:cryptography/cryptography.dart';

class DH {
  static BigInt _randomBigInt(int numberBytes) {
    final random = Random.secure();
    var value = BigInt.from(0);
    for (var i = 0; i < numberBytes; ++i) {
      value <<= 8;
      value |= BigInt.from(random.nextInt(256));
    }
    return value;
  }

  static BigInt generatePrivateKey() {
    return DH._randomBigInt(32); // 256 bits
  }

  static BigInt calcPublicKey(
    BigInt gKey,
    BigInt nKey,
    BigInt privKey,
  ) {
    return gKey.modPow(privKey, nKey);
  }

  static Future<List<int>> calcSecretKey(
    BigInt nKey,
    BigInt clientPrivKey,
    BigInt serverPubKey,
  ) async {
    final sharedKey = serverPubKey.modPow(clientPrivKey, nKey);
    final secretKey = await Sha256().hash(sharedKey.toString().codeUnits);
    return Future.value(secretKey.bytes);
  }
}
