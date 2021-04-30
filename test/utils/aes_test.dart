import 'package:cso_client_flutter/utils/aes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Encrypt", () async {
    final key = [
      140,
      34,
      32,
      16,
      190,
      30,
      86,
      112,
      191,
      254,
      35,
      254,
      55,
      187,
      216,
      183,
      228,
      35,
      121,
      11,
      185,
      179,
      187,
      112,
      170,
      190,
      126,
      218,
      85,
      61,
      28,
      93,
    ];
    final data = "Goldeneye Technologies".codeUnits;
    final aad = "Goldeneye Cloud Socket".codeUnits;
    final cipher = await AES.encrypt(key, data, aad);
    final msg = await AES.decrypt(
      key,
      cipher.nonce,
      cipher.mac.bytes,
      cipher.cipherText,
      aad,
    );
    expect(msg, data);
  });

  test("Decrypt", () async {
    final expectedMsg = "Goldeneye Technologies".codeUnits;
    final aad = "Goldeneye Cloud Socket".codeUnits;
    final key = [
      140,
      34,
      32,
      16,
      190,
      30,
      86,
      112,
      191,
      254,
      35,
      254,
      55,
      187,
      216,
      183,
      228,
      35,
      121,
      11,
      185,
      179,
      187,
      112,
      170,
      190,
      126,
      218,
      85,
      61,
      28,
      93,
    ];
    final iv = [
      68,
      68,
      112,
      15,
      17,
      145,
      19,
      172,
      188,
      31,
      15,
      69,
    ];
    final authenTag = [
      170,
      251,
      82,
      234,
      140,
      139,
      57,
      223,
      65,
      172,
      74,
      130,
      63,
      168,
      231,
      63,
    ];
    final cipher = [
      183,
      226,
      253,
      107,
      136,
      203,
      236,
      30,
      173,
      76,
      207,
      202,
      221,
      20,
      235,
      144,
      202,
      70,
      78,
      15,
      13,
      31,
    ];
    final msg = await AES.decrypt(
      key,
      iv,
      authenTag,
      cipher,
      aad,
    );
    expect(msg, expectedMsg);
  });
}
