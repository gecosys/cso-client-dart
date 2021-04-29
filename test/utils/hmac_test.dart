import 'dart:typed_data';

import 'package:cso_client_flutter/utils/hmac.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';

void main() {
  test('Calculate HMAC', () async {
    final expectedHMAC = [
      47,
      121,
      108,
      13,
      177,
      58,
      58,
      235,
      166,
      113,
      132,
      61,
      39,
      64,
      75,
      230,
      76,
      184,
      174,
      11,
      168,
      45,
      78,
      208,
      199,
      49,
      165,
      159,
      244,
      138,
      139,
      47,
    ];
    final key = await Sha256().hash(Uint8List.fromList([
      114,
      203,
      246,
      0,
      37,
      216,
      117,
      58,
      193,
      41,
      160,
      114,
      203,
      246,
      0,
      37,
      216,
      117,
      58,
      193,
      41,
      160,
      124,
      41,
      159,
      100,
      79,
      136,
      82,
      108,
      22,
      76
    ]));
    final data = Uint8List.fromList("Goldeneye Technologies".codeUnits);
    final hmac = await HMAC.calcHMAC(Uint8List.fromList(key.bytes), data);
    expect(hmac, expectedHMAC);
  });
  test('Validate HMAC', () async {
    final expectedHMAC = [
      47,
      121,
      108,
      13,
      177,
      58,
      58,
      235,
      166,
      113,
      132,
      61,
      39,
      64,
      75,
      230,
      76,
      184,
      174,
      11,
      168,
      45,
      78,
      208,
      199,
      49,
      165,
      159,
      244,
      138,
      139,
      47,
    ];
    final key = await Sha256().hash(Uint8List.fromList([
      114,
      203,
      246,
      0,
      37,
      216,
      117,
      58,
      193,
      41,
      160,
      114,
      203,
      246,
      0,
      37,
      216,
      117,
      58,
      193,
      41,
      160,
      124,
      41,
      159,
      100,
      79,
      136,
      82,
      108,
      22,
      76
    ]));

    var data = Uint8List.fromList("Goldeneye Technologies".codeUnits);
    var isSuccess = await HMAC.validateHMAC(
      Uint8List.fromList(key.bytes),
      data,
      Uint8List.fromList(expectedHMAC),
    );
    expect(isSuccess, true);

    data = Uint8List.fromList("Goldeneye Technologies Fake".codeUnits);
    isSuccess = await HMAC.validateHMAC(
      Uint8List.fromList(key.bytes),
      data,
      Uint8List.fromList(expectedHMAC),
    );
    expect(isSuccess, false);
  });
}
