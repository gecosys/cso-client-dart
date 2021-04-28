import 'dart:typed_data';

import 'package:cso_client_flutter/cso/message/define.dart';
import 'package:cso_client_flutter/cso/message/readyticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Parse bytes', () {
    var input = Uint8List.fromList([
      1,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      254,
      255,
      255,
      255,
      255,
      255,
      255,
      255
    ]);
    var result = ReadyTicket.parseBytes(input.buffer);
    expect(result.errorCode, ErrorCode.success);
    expect(result.data.getIsReady(), true);
    expect(
      result.data.getIdxRead(),
      BigInt.parse("18446744073709551615").toUnsigned(64),
    );
    expect(
      result.data.getMaskRead(),
      BigInt.from(4294967295).toUnsigned(32),
    );
    expect(
      result.data.getIdxWrite(),
      BigInt.parse("18446744073709551614").toUnsigned(64),
    );

    input = Uint8List.fromList([
      0,
      254,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255
    ]);
    result = ReadyTicket.parseBytes(input.buffer);
    expect(result.errorCode, ErrorCode.success);
    expect(result.data.getIsReady(), false);
    expect(
      result.data.getIdxRead(),
      BigInt.parse("18446744073709551614").toUnsigned(64),
    );
    expect(
      result.data.getMaskRead(),
      BigInt.from(4294967295).toUnsigned(32),
    );
    expect(
      result.data.getIdxWrite(),
      BigInt.parse("18446744073709551615").toUnsigned(64),
    );
  });
}
