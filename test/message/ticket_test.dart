import 'dart:typed_data';

import 'package:gecosys_cso_client/src/message/define.dart';
import 'package:gecosys_cso_client/src/message/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Parse bytes', () {
    var expectedToken = [
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
    ];
    var input = [
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
    ];

    var ticket = Ticket.parseBytes(Uint8List.fromList(input).buffer);
    expect(ticket.errorCode, ErrorCode.success);
    expect(ticket.data.id, BigInt.from(65535).toUnsigned(16));
    expect(ticket.data.token, expectedToken);
  });
}
