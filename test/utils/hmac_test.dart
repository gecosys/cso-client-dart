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
    final key = await Sha256().hash([
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
    ]);
    final hmac = await HMAC.calcHMAC(
      key.bytes,
      "Goldeneye Technologies".codeUnits,
    );
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
    final key = await Sha256().hash([
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
    ]);

    final isSuccess = await HMAC.validateHMAC(
      key.bytes,
      "Goldeneye Technologies".codeUnits,
      expectedHMAC,
    );
    expect(isSuccess, true);
  });
  test('Validate HMAC with wrong data', () async {
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
    final key = await Sha256().hash([
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
    ]);

    final isSuccess = await HMAC.validateHMAC(
      key.bytes,
      "Goldeneye Technologies Fake".codeUnits,
      expectedHMAC,
    );
    expect(isSuccess, false);
  });
  test('Validate HMAC with wrong key', () async {
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
    final key = await Sha256().hash([
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
      109,
      22,
      76
    ]);

    final isSuccess = await HMAC.validateHMAC(
      key.bytes,
      "Goldeneye Technologies".codeUnits,
      expectedHMAC,
    );
    expect(isSuccess, false);
  });
}
