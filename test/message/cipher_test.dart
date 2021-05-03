import 'dart:math';
import 'dart:typed_data';

import 'package:cso_client_flutter/src/message/cipher.dart';
import 'package:cso_client_flutter/src/message/define.dart';
import 'package:cso_client_flutter/src/message/type.dart';
import 'package:flutter_test/flutter_test.dart';

const gConnName = "goldeneye_technologies";

void main() {
  test('Build raw bytes', () => testBuildRawBytes());
  test('Build aad', () => testBuildAad());
  test('Into bytes', () => testIntoBytes());
  test('Parse cipher bytes', () => testParseCipherBytes());
  test('Parse no cipher bytes', () => testParseNoCipherBytes());
}

void testBuildRawBytes() {
  var expectedBytes = [
    0,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    251,
    22,
    1,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    103,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    95,
    116,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115,
    71,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    32,
    84,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115
  ];
  var rawBytes = Cipher.buildRawBytes(
    1024,
    1025,
    MessageType.single,
    true,
    true,
    true,
    true,
    gConnName,
    "Goldeneye Technologies".codeUnits,
  );
  expect(rawBytes.errorCode, ErrorCode.success);
  expect(rawBytes.data, expectedBytes);

  runCases((
    msgID,
    msgTag,
    msgType,
    iv,
    data,
    authenTag,
    sign,
    isFirst,
    isLast,
    isRequest,
    isEncrypted,
  ) {
    var cipher = Cipher(
      msgID: msgID,
      msgType: msgType,
      msgTag: msgTag,
      isFirst: isFirst,
      isLast: isLast,
      isRequest: isRequest,
      isEncrypted: isEncrypted,
      name: gConnName,
      iv: iv,
      data: data,
      authenTag: authenTag,
      sign: sign,
    );

    var expectedRawBytes = cipher.getRawBytes();
    expect(expectedRawBytes.errorCode, ErrorCode.success);

    var rawBytes = Cipher.buildRawBytes(
      msgID,
      msgTag,
      msgType,
      isEncrypted,
      isFirst,
      isLast,
      isRequest,
      gConnName,
      data,
    );
    expect(rawBytes.errorCode, ErrorCode.success);
    expect(rawBytes.data, expectedRawBytes.data);
  });
}

void testBuildAad() {
  var expectedAad = [
    0,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    251,
    22,
    1,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    103,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    95,
    116,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115
  ];
  var aad = Cipher.buildAad(
    1024,
    1025,
    MessageType.single,
    true,
    true,
    true,
    true,
    gConnName,
  );
  expect(aad.errorCode, ErrorCode.success);
  expect(aad.data, expectedAad);

  runCases((
    msgID,
    msgTag,
    msgType,
    iv,
    data,
    authenTag,
    sign,
    isFirst,
    isLast,
    isRequest,
    isEncrypted,
  ) {
    var cipher = Cipher(
      msgID: msgID,
      msgType: msgType,
      msgTag: msgTag,
      isFirst: isFirst,
      isLast: isLast,
      isRequest: isRequest,
      isEncrypted: isEncrypted,
      name: gConnName,
      iv: iv,
      data: data,
      authenTag: authenTag,
      sign: sign,
    );

    var expectedAad = cipher.getAad();
    expect(expectedAad.errorCode, ErrorCode.success);

    var aad = Cipher.buildAad(
      msgID,
      msgTag,
      msgType,
      isEncrypted,
      isFirst,
      isLast,
      isRequest,
      gConnName,
    );
    expect(aad.errorCode, ErrorCode.success);
    expect(aad.data, expectedAad.data);
  });
}

void testIntoBytes() {
  runCases((
    msgID,
    msgTag,
    msgType,
    iv,
    data,
    authenTag,
    sign,
    isFirst,
    isLast,
    isRequest,
    isEncrypted,
  ) {
    var cipher = Cipher(
      msgID: msgID,
      msgType: msgType,
      msgTag: msgTag,
      isFirst: isFirst,
      isLast: isLast,
      isRequest: isRequest,
      isEncrypted: isEncrypted,
      name: gConnName,
      iv: iv,
      data: data,
      authenTag: authenTag,
      sign: sign,
    );

    var bytes = cipher.intoBytes();
    expect(bytes.errorCode, ErrorCode.success);

    var parsedCipher = Cipher.parseBytes(Uint8List.fromList(bytes.data).buffer);
    expect(parsedCipher.errorCode, ErrorCode.success);
    expect(parsedCipher.data.getIsEncrypted(), isEncrypted);
    expect(parsedCipher.data.getIsFirst(), isFirst);
    expect(parsedCipher.data.getIsLast(), isLast);
    expect(parsedCipher.data.getIsRequest(), isRequest);
    expect(
      parsedCipher.data.getMsgID(),
      BigInt.from(msgID).toUnsigned(64),
    );
    expect(
      parsedCipher.data.getMsgTag(),
      BigInt.from(msgTag).toUnsigned(64),
    );
    expect(parsedCipher.data.getMsgType(), msgType);
    expect(parsedCipher.data.getName(), gConnName);
    if (parsedCipher.data.getIsEncrypted()) {
      expect(parsedCipher.data.getIV(), iv);
      expect(parsedCipher.data.getAuthenTag(), authenTag);
    } else {
      expect(parsedCipher.data.getSign(), sign);
    }

    // var aad = cipher.getAad();
    // var parsedAad = parsedCipher.data.getAad();
    // expect(aad.errorCode, ErrorCode.success);
    // expect(parsedAad.errorCode, ErrorCode.success);
    // expect(parsedAad.data, aad.data);
    // expect(parsedCipher.data.getData(), data);
  });
}

void testParseCipherBytes() {
  var expectedIsEncrypted = true;
  var expectedIsFirst = true;
  var expectedIsLast = true;
  var expectedIsRequest = true;
  var expectedMessageID = 1024;
  var expectedMessageTag = 1025;
  var expectedMessageType = MessageType.single;
  var expectedName = gConnName;
  var expectedIV = [
    52,
    69,
    113,
    36,
    207,
    171,
    168,
    50,
    162,
    40,
    224,
    187,
  ];
  var expectedAuthenTag = [
    106,
    232,
    205,
    181,
    53,
    106,
    177,
    50,
    190,
    131,
    144,
    7,
    101,
    44,
    27,
    45,
  ];
  var expectedData = "Goldeneye Technologies".codeUnits;
  var expectedAad = [
    0,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    251,
    22,
    1,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    103,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    95,
    116,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115,
  ];
  var input = [
    0,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    251,
    22,
    1,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    106,
    232,
    205,
    181,
    53,
    106,
    177,
    50,
    190,
    131,
    144,
    7,
    101,
    44,
    27,
    45,
    52,
    69,
    113,
    36,
    207,
    171,
    168,
    50,
    162,
    40,
    224,
    187,
    103,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    95,
    116,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115,
    71,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    32,
    84,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115,
  ];
  var cipher = Cipher.parseBytes(Uint8List.fromList(input).buffer);
  expect(cipher.errorCode, ErrorCode.success);
  expect(cipher.data.getIsEncrypted(), expectedIsEncrypted);
  expect(cipher.data.getIsFirst(), expectedIsFirst);
  expect(cipher.data.getIsLast(), expectedIsLast);
  expect(cipher.data.getIsRequest(), expectedIsRequest);
  expect(
    cipher.data.getMsgID(),
    BigInt.from(expectedMessageID).toUnsigned(64),
  );
  expect(
    cipher.data.getMsgTag(),
    BigInt.from(expectedMessageTag).toUnsigned(64),
  );
  expect(cipher.data.getMsgType(), expectedMessageType);
  expect(cipher.data.getName(), expectedName);
  expect(cipher.data.getIV(), expectedIV);
  expect(cipher.data.getAuthenTag(), expectedAuthenTag);

  var aad = cipher.data.getAad();
  expect(aad.errorCode, ErrorCode.success);
  expect(aad.data, expectedAad);
  expect(cipher.data.getData(), expectedData);
}

void testParseNoCipherBytes() {
  var expectedIsEncrypted = false;
  var expectedIsFirst = true;
  var expectedIsLast = true;
  var expectedIsRequest = true;
  var expectedMessageID = 1024;
  var expectedMessageTag = 1025;
  var expectedMessageType = MessageType.single;
  var expectedName = gConnName;
  var expectedAad = [
    0,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    123,
    22,
    1,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    103,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    95,
    116,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115,
  ];
  var expectedSign = [
    140,
    57,
    139,
    30,
    167,
    65,
    206,
    46,
    33,
    131,
    181,
    152,
    42,
    206,
    205,
    79,
    59,
    223,
    16,
    25,
    61,
    95,
    68,
    163,
    49,
    147,
    106,
    188,
    66,
    151,
    202,
    88,
  ];
  var expectedData = "Goldeneye Technologies".codeUnits;
  var input = [
    0,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    123,
    22,
    1,
    4,
    0,
    0,
    0,
    0,
    0,
    0,
    140,
    57,
    139,
    30,
    167,
    65,
    206,
    46,
    33,
    131,
    181,
    152,
    42,
    206,
    205,
    79,
    59,
    223,
    16,
    25,
    61,
    95,
    68,
    163,
    49,
    147,
    106,
    188,
    66,
    151,
    202,
    88,
    103,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    95,
    116,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115,
    71,
    111,
    108,
    100,
    101,
    110,
    101,
    121,
    101,
    32,
    84,
    101,
    99,
    104,
    110,
    111,
    108,
    111,
    103,
    105,
    101,
    115,
  ];

  var cipher = Cipher.parseBytes(Uint8List.fromList(input).buffer);
  expect(cipher.errorCode, ErrorCode.success);
  expect(cipher.data.getIsEncrypted(), expectedIsEncrypted);
  expect(cipher.data.getIsFirst(), expectedIsFirst);
  expect(cipher.data.getIsLast(), expectedIsLast);
  expect(cipher.data.getIsRequest(), expectedIsRequest);
  expect(
    cipher.data.getMsgID(),
    BigInt.from(expectedMessageID).toUnsigned(64),
  );
  expect(
    cipher.data.getMsgTag(),
    BigInt.from(expectedMessageTag).toUnsigned(64),
  );
  expect(cipher.data.getMsgType(), expectedMessageType);
  expect(cipher.data.getName(), expectedName);
  expect(cipher.data.getSign(), expectedSign);

  var aad = cipher.data.getAad();
  expect(aad.errorCode, ErrorCode.success);
  expect(aad.data, expectedAad);
  expect(cipher.data.getData(), expectedData);
}

void runCases(
  runner(
      int msgID,
      int msgTag,
      MessageType msgType,
      List<int> iv,
      List<int> data,
      List<int> authenTag,
      List<int> sign,
      bool isFirst,
      bool isLast,
      bool isRequest,
      bool isEncrypted),
) {
  var isEncrypted = true;
  var msgTypes = [
    MessageType.activation,
    MessageType.single,
    MessageType.group,
    MessageType.singleCached,
    MessageType.groupCached,
    MessageType.done,
  ];
  var flagTables = [
    [true, true, true], // first, last, request
    [false, true, true],
    [true, false, true],
    [true, true, false],
    [false, false, true],
    [true, false, false],
    [false, true, false],
    [false, false, false]
  ];

  final random = Random.secure();
  for (var i = 0; i < 2; ++i) {
    isEncrypted = !isEncrypted;
    for (var msgType in msgTypes) {
      for (var flagsTable in flagTables) {
        var msgID = Uint8List.fromList(
          List.generate(64, (index) => random.nextInt(256)),
        ).buffer.asByteData(0).getUint64(0);
        var msgTag = Uint8List.fromList(
          List.generate(64, (index) => random.nextInt(256)),
        ).buffer.asByteData(0).getUint64(0);
        var iv = List.generate(12, (index) => random.nextInt(256));
        var data = List.generate(1024, (index) => random.nextInt(256));
        var authenTag = List.generate(16, (index) => random.nextInt(256));
        var sign = List.generate(32, (index) => random.nextInt(256));

        var isFirst = flagsTable[0];
        var isLast = flagsTable[1];
        var isRequest = flagsTable[2];
        runner(
          msgID,
          msgTag,
          msgType,
          iv,
          data,
          authenTag,
          sign,
          isFirst,
          isLast,
          isRequest,
          isEncrypted,
        );
      }
    }
  }
}
