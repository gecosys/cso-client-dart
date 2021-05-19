import 'dart:typed_data';

import 'package:gecosys_cso_client/src/message/define.dart';
import 'package:gecosys_cso_client/src/message/readyticket.dart';
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
    expect(result.data.isReady, true);
    expect(
      result.data.idxRead,
      BigInt.parse("18446744073709551615").toUnsigned(64),
    );
    expect(
      result.data.maskRead,
      BigInt.from(4294967295).toUnsigned(32),
    );
    expect(
      result.data.idxWrite,
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
    expect(result.data.isReady, false);
    expect(
      result.data.idxRead,
      BigInt.parse("18446744073709551614").toUnsigned(64),
    );
    expect(
      result.data.maskRead,
      BigInt.from(4294967295).toUnsigned(32),
    );
    expect(
      result.data.idxWrite,
      BigInt.parse("18446744073709551615").toUnsigned(64),
    );
  });
}
