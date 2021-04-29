import 'dart:typed_data';

import 'package:cso_client_flutter/message/result.dart';
import 'package:cso_client_flutter/message/type.dart';

import 'define.dart';

// MaxConnectionNameLength is max length of connections's name
const MaxConnectionNameLength = 36;

class Cipher {
  int _msgID;
  MessageType _msgType;
  int _msgTag;
  bool _isFirst;
  bool _isLast;
  bool _isRequest;
  bool _isEncrypted;
  String _name;
  Uint8List _iv;
  Uint8List _data;
  Uint8List _authenTag;
  Uint8List _sign;

  Cipher({
    required int msgID,
    required MessageType msgType,
    required int msgTag,
    required bool isFirst,
    required bool isLast,
    required bool isRequest,
    required bool isEncrypted,
    required String name,
    required Uint8List iv,
    required Uint8List data,
    required Uint8List authenTag,
    required Uint8List sign,
  })   : _msgID = msgID,
        _msgType = msgType,
        _msgTag = msgTag,
        _isFirst = isFirst,
        _isLast = isLast,
        _isRequest = isRequest,
        _isEncrypted = isEncrypted,
        _name = name,
        _iv = iv,
        _data = data,
        _authenTag = authenTag,
        _sign = sign;

  BigInt getMsgID() {
    return BigInt.from(this._msgID).toUnsigned(64);
  }

  MessageType getMsgType() {
    return this._msgType;
  }

  BigInt getMsgTag() {
    return BigInt.from(this._msgTag).toUnsigned(64);
  }

  bool getIsFirst() {
    return this._isFirst;
  }

  bool getIsLast() {
    return this._isLast;
  }

  bool getIsRequest() {
    return this._isRequest;
  }

  bool getIsEncrypted() {
    return this._isEncrypted;
  }

  String getName() {
    return this._name;
  }

  Uint8List getIV() {
    return this._iv;
  }

  Uint8List getAuthenTag() {
    return this._authenTag;
  }

  Uint8List getData() {
    return this._data;
  }

  Uint8List getSign() {
    return this._sign;
  }

  static Cipher newDefault() {
    return Cipher(
      msgID: 0,
      msgType: MessageType.single,
      msgTag: 0,
      isFirst: false,
      isLast: false,
      isRequest: false,
      isEncrypted: false,
      name: "",
      iv: Uint8List(0),
      data: Uint8List(0),
      authenTag: Uint8List(0),
      sign: Uint8List(0),
    );
  }

  Result<Uint8List> intoBytes() {
    if (this._isEncrypted) {
      return Cipher.buildCipherBytes(
        this._msgID,
        this._msgTag,
        this._msgType,
        this._isFirst,
        this._isLast,
        this._isRequest,
        this._name,
        this._iv,
        this._data,
        this._authenTag,
      );
    }
    return Cipher.buildNoCipherBytes(
      this._msgID,
      this._msgTag,
      this._msgType,
      this._isFirst,
      this._isLast,
      this._isRequest,
      this._name,
      this._data,
      this._sign,
    );
  }

  Result<Uint8List> getRawBytes() {
    return Cipher.buildRawBytes(
      this._msgID,
      this._msgTag,
      this._msgType,
      this._isEncrypted,
      this._isFirst,
      this._isLast,
      this._isRequest,
      this._name,
      this._data,
    );
  }

  Result<Uint8List> getAad() {
    return Cipher.buildAad(
      this._msgID,
      this._msgTag,
      this._msgType,
      this._isEncrypted,
      this._isFirst,
      this._isLast,
      this._isRequest,
      this._name,
    );
  }

  // ParseBytes converts bytes to Cipher
  // ID of message: 8 bytes
  // Encrypted, First, Last, Request/Response, Tag, Type (3 bits): 1 byte
  // Length of Name (nName): 1 byte
  // Tag: if flag of tag = 1 then 8 bytes, otherwise 0 byte
  // AUTHEN_TAG: if encrypted is true then 16 bytes, otherwise 0 byte
  // IV: if encrypted is true then 12 bytes, otherwise 0 byte
  // Sign: if encrypted is false then 32 bytes (HMAC-SHA256), otherwise 0 byte
  // Name: nName bytes
  // Data: remaining bytes
  static Result<Cipher> parseBytes(ByteBuffer buffer) {
    var fixedLen = 10;
    var posAuthenTag = 10;
    var lenBuffer = buffer.lengthInBytes;
    if (lenBuffer < fixedLen) {
      return Result(
        errorCode: ErrorCode.invalidBytes,
        data: Cipher.newDefault(),
      );
    }

    var bytes = buffer.asByteData(0, lenBuffer);
    var flag = bytes.getUint8(8);
    var isEncrypted = (flag & 0x80) != 0;
    var msgID = bytes.getUint64(0, Endian.little);
    var lenName = bytes.getUint8(9);
    var msgTag = 0;

    // Use message's tag
    if ((flag & 0x08) != 0) {
      fixedLen += 8;
      posAuthenTag += 8;
      if (lenBuffer < fixedLen) {
        return Result(
          errorCode: ErrorCode.invalidBytes,
          data: Cipher.newDefault(),
        );
      }
      msgTag = bytes.getUint64(10, Endian.little);
    }

    if (isEncrypted) {
      fixedLen += 28; // authenTag (16) + iv (12)
    }

    if (lenName == 0 || lenName > MaxConnectionNameLength) {
      return Result(
        errorCode: ErrorCode.invalidConnectionName,
        data: Cipher.newDefault(),
      );
    }
    if (lenBuffer < (fixedLen + lenName)) {
      return Result(
        errorCode: ErrorCode.invalidBytes,
        data: Cipher.newDefault(),
      );
    }

    // Parse AUTHEN_TAG, IV
    Uint8List authenTag;
    Uint8List iv;
    Uint8List sign;
    if (isEncrypted) {
      var posIV = posAuthenTag + Constant.lengthAuthenTag;
      authenTag = buffer.asUint8List(posAuthenTag, Constant.lengthAuthenTag);
      iv = buffer.asUint8List(posIV, Constant.lengthIV);
      sign = Uint8List(0);
    } else {
      var posSign = fixedLen;
      fixedLen += Constant.lengthSign;
      if (lenBuffer < (fixedLen + lenName)) {
        return Result(
          errorCode: ErrorCode.invalidBytes,
          data: Cipher.newDefault(),
        );
      }
      authenTag = Uint8List(0);
      iv = Uint8List(0);
      sign = buffer.asUint8List(posSign, Constant.lengthSign);
    }

    // Parse name
    var posData = fixedLen + lenName;
    var name = String.fromCharCodes(buffer.asUint8List(fixedLen, lenName));

    // Parse data
    var lenData = lenBuffer - posData;
    Uint8List data;
    if (lenData > 0) {
      data = buffer.asUint8List(posData);
    } else {
      data = Uint8List(0);
    }

    return Result(
      errorCode: ErrorCode.success,
      data: Cipher(
        msgID: msgID,
        msgType: MessageType.parse(flag & 0x07),
        msgTag: msgTag,
        isFirst: (flag & 0x40) != 0,
        isLast: (flag & 0x20) != 0,
        isRequest: (flag & 0x10) != 0,
        isEncrypted: isEncrypted,
        name: name,
        iv: iv,
        data: data,
        authenTag: authenTag,
        sign: sign,
      ),
    );
  }

  static Result<Uint8List> buildRawBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isEncrypted,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    Uint8List data,
  ) {
    var lenName = name.length;
    if (lenName == 0 || lenName > MaxConnectionNameLength) {
      return Result(
        errorCode: ErrorCode.invalidConnectionName,
        data: Uint8List(0),
      );
    }
    var lenData = data.lengthInBytes;

    var bEncrypted = isEncrypted ? 1 : 0;
    var bFirst = isFirst ? 1 : 0;
    var bLast = isLast ? 1 : 0;
    var bRequest = isRequest ? 1 : 0;
    var bUseTag = 0;

    var fixedLen = 10;
    var valMsgID = BigInt.from(msgID).toUnsigned(64);
    var valMsgTag = BigInt.from(msgTag).toUnsigned(64);
    if (valMsgTag > BigInt.zero) {
      bUseTag = 1;
      fixedLen += 8;
    }

    var buffer = Uint8List(fixedLen + lenName + lenData);
    buffer[0] = valMsgID.toUnsigned(8).toInt();
    buffer[1] = (valMsgID >> 8).toUnsigned(8).toInt();
    buffer[2] = (valMsgID >> 16).toUnsigned(8).toInt();
    buffer[3] = (valMsgID >> 24).toUnsigned(8).toInt();
    buffer[4] = (valMsgID >> 32).toUnsigned(8).toInt();
    buffer[5] = (valMsgID >> 40).toUnsigned(8).toInt();
    buffer[6] = (valMsgID >> 48).toUnsigned(8).toInt();
    buffer[7] = (valMsgID >> 56).toUnsigned(8).toInt();
    buffer[8] = bEncrypted << 7 |
        bFirst << 6 |
        bLast << 5 |
        bRequest << 4 |
        bUseTag << 3 |
        msgType.toValue();
    buffer[9] = lenName;
    if (valMsgTag > BigInt.zero) {
      buffer[10] = valMsgTag.toUnsigned(8).toInt();
      buffer[11] = (valMsgTag >> 8).toUnsigned(8).toInt();
      buffer[12] = (valMsgTag >> 16).toUnsigned(8).toInt();
      buffer[13] = (valMsgTag >> 24).toUnsigned(8).toInt();
      buffer[14] = (valMsgTag >> 32).toUnsigned(8).toInt();
      buffer[15] = (valMsgTag >> 40).toUnsigned(8).toInt();
      buffer[16] = (valMsgTag >> 48).toUnsigned(8).toInt();
      buffer[17] = (valMsgTag >> 56).toUnsigned(8).toInt();
    }
    buffer.setAll(fixedLen, name.codeUnits);
    if (lenData > 0) {
      buffer.setAll(fixedLen + lenName, data);
    }

    return Result(
      errorCode: ErrorCode.success,
      data: buffer,
    );
  }

  static Result<Uint8List> buildAad(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isEncrypted,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
  ) {
    var lenName = name.length;
    if (lenName == 0 || lenName > MaxConnectionNameLength) {
      return Result(
        errorCode: ErrorCode.invalidConnectionName,
        data: Uint8List(0),
      );
    }

    var bEncrypted = isEncrypted ? 1 : 0;
    var bFirst = isFirst ? 1 : 0;
    var bLast = isLast ? 1 : 0;
    var bRequest = isRequest ? 1 : 0;
    var bUseTag = 0;

    var fixedLen = 10;
    var valMsgID = BigInt.from(msgID).toUnsigned(64);
    var valMsgTag = BigInt.from(msgTag).toUnsigned(64);
    if (valMsgTag > BigInt.zero) {
      bUseTag = 1;
      fixedLen += 8;
    }

    var buffer = Uint8List(fixedLen + lenName);
    buffer[0] = valMsgID.toUnsigned(8).toInt();
    buffer[1] = (valMsgID >> 8).toUnsigned(8).toInt();
    buffer[2] = (valMsgID >> 16).toUnsigned(8).toInt();
    buffer[3] = (valMsgID >> 24).toUnsigned(8).toInt();
    buffer[4] = (valMsgID >> 32).toUnsigned(8).toInt();
    buffer[5] = (valMsgID >> 40).toUnsigned(8).toInt();
    buffer[6] = (valMsgID >> 48).toUnsigned(8).toInt();
    buffer[7] = (valMsgID >> 56).toUnsigned(8).toInt();
    buffer[8] = bEncrypted << 7 |
        bFirst << 6 |
        bLast << 5 |
        bRequest << 4 |
        bUseTag << 3 |
        msgType.toValue();
    buffer[9] = lenName;
    if (valMsgTag > BigInt.zero) {
      buffer[10] = valMsgTag.toUnsigned(8).toInt();
      buffer[11] = (valMsgTag >> 8).toUnsigned(8).toInt();
      buffer[12] = (valMsgTag >> 16).toUnsigned(8).toInt();
      buffer[13] = (valMsgTag >> 24).toUnsigned(8).toInt();
      buffer[14] = (valMsgTag >> 32).toUnsigned(8).toInt();
      buffer[15] = (valMsgTag >> 40).toUnsigned(8).toInt();
      buffer[16] = (valMsgTag >> 48).toUnsigned(8).toInt();
      buffer[17] = (valMsgTag >> 56).toUnsigned(8).toInt();
    }
    buffer.setAll(fixedLen, name.codeUnits);

    return Result(
      errorCode: ErrorCode.success,
      data: buffer,
    );
  }

  static Result<Uint8List> buildCipherBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    Uint8List iv,
    Uint8List data,
    Uint8List authenTag,
  ) {
    return Cipher.buildBytes(
      msgID,
      msgTag,
      msgType,
      true,
      isFirst,
      isLast,
      isRequest,
      name,
      iv,
      data,
      authenTag,
      Uint8List(0),
    );
  }

  static Result<Uint8List> buildNoCipherBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    Uint8List data,
    Uint8List sign,
  ) {
    var empty = Uint8List(0);
    return Cipher.buildBytes(
      msgID,
      msgTag,
      msgType,
      false,
      isFirst,
      isLast,
      isRequest,
      name,
      empty,
      data,
      empty,
      sign,
    );
  }

  static Result<Uint8List> buildBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isEncrypted,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    Uint8List iv,
    Uint8List data,
    Uint8List authenTag,
    Uint8List sign,
  ) {
    var lenName = name.length;
    if (lenName == 0 || lenName > MaxConnectionNameLength) {
      return Result(
        errorCode: ErrorCode.invalidConnectionName,
        data: Uint8List(0),
      );
    }

    var lenIV = iv.lengthInBytes;
    var lenAuthenTag = authenTag.lengthInBytes;
    var lenSign = sign.lengthInBytes;
    if (isEncrypted) {
      if (lenIV != Constant.lengthIV ||
          lenAuthenTag != Constant.lengthAuthenTag) {
        return Result(
          errorCode: ErrorCode.invalidBytes,
          data: Uint8List(0),
        );
      }
      lenSign = 0;
    } else {
      if (lenSign != Constant.lengthSign) {
        return Result(
          errorCode: ErrorCode.invalidBytes,
          data: Uint8List(0),
        );
      }
      lenIV = 0;
      lenAuthenTag = 0;
    }

    var bEncrypted = isEncrypted ? 1 : 0;
    var bFirst = isFirst ? 1 : 0;
    var bLast = isLast ? 1 : 0;
    var bRequest = isRequest ? 1 : 0;
    var bUseTag = 0;

    var fixedLen = 10;
    var valMsgID = BigInt.from(msgID).toUnsigned(64);
    var valMsgTag = BigInt.from(msgTag).toUnsigned(64);
    if (valMsgTag > BigInt.zero) {
      bUseTag = 1;
      fixedLen += 8;
    }

    var lenData = data.lengthInBytes;
    var lenBuffer =
        fixedLen + lenAuthenTag + lenIV + lenSign + lenName + lenData;
    var buffer = Uint8List(lenBuffer);
    buffer[0] = valMsgID.toUnsigned(8).toInt();
    buffer[1] = (valMsgID >> 8).toUnsigned(8).toInt();
    buffer[2] = (valMsgID >> 16).toUnsigned(8).toInt();
    buffer[3] = (valMsgID >> 24).toUnsigned(8).toInt();
    buffer[4] = (valMsgID >> 32).toUnsigned(8).toInt();
    buffer[5] = (valMsgID >> 40).toUnsigned(8).toInt();
    buffer[6] = (valMsgID >> 48).toUnsigned(8).toInt();
    buffer[7] = (valMsgID >> 56).toUnsigned(8).toInt();
    buffer[8] = bEncrypted << 7 |
        bFirst << 6 |
        bLast << 5 |
        bRequest << 4 |
        bUseTag << 3 |
        msgType.toValue();
    buffer[9] = lenName;
    if (valMsgTag > BigInt.zero) {
      buffer[10] = valMsgTag.toUnsigned(8).toInt();
      buffer[11] = (valMsgTag >> 8).toUnsigned(8).toInt();
      buffer[12] = (valMsgTag >> 16).toUnsigned(8).toInt();
      buffer[13] = (valMsgTag >> 24).toUnsigned(8).toInt();
      buffer[14] = (valMsgTag >> 32).toUnsigned(8).toInt();
      buffer[15] = (valMsgTag >> 40).toUnsigned(8).toInt();
      buffer[16] = (valMsgTag >> 48).toUnsigned(8).toInt();
      buffer[17] = (valMsgTag >> 56).toUnsigned(8).toInt();
    }
    var posData = fixedLen + lenAuthenTag;
    if (isEncrypted) {
      buffer.setAll(fixedLen, authenTag);
      buffer.setAll(posData, iv);
      posData += lenIV;
    } else {
      buffer.setAll(fixedLen, sign);
      posData += lenSign;
    }
    buffer.setAll(posData, name.codeUnits);
    posData += lenName;
    if (lenData > 0) {
      buffer.setAll(posData, data);
    }

    return Result(
      errorCode: ErrorCode.success,
      data: buffer,
    );
  }
}
