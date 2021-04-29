import 'dart:typed_data';

import 'package:cso_client_flutter/message/define.dart';
import 'package:cso_client_flutter/message/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Parse bytes', () {
    var expectedToken = Uint8List.fromList([
      213,
      132,
      113,
      225,
      37,
      37,
      160,
      13,
      148,
      229,
      56,
      218,
      115,
      1,
      210,
      66,
      139,
      49,
      12,
      110,
      98,
      125,
      191,
      231,
      51,
      72,
      235,
      166,
      185,
      76,
      66,
      238,
    ]);
    var input = Uint8List.fromList([
      255,
      255,
      213,
      132,
      113,
      225,
      37,
      37,
      160,
      13,
      148,
      229,
      56,
      218,
      115,
      1,
      210,
      66,
      139,
      49,
      12,
      110,
      98,
      125,
      191,
      231,
      51,
      72,
      235,
      166,
      185,
      76,
      66,
      238,
    ]);

    var ticket = Ticket.parseBytes(input.buffer);
    expect(ticket.errorCode, ErrorCode.success);
    expect(ticket.data.getID(), BigInt.from(65535).toUnsigned(16));
    expect(ticket.data.getToken(), expectedToken);
  });
}
