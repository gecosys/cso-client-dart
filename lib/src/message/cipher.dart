import 'dart:typed_data';

import 'package:cso_client_flutter/src/message/result.dart';
import 'package:cso_client_flutter/src/message/type.dart';

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
  List<int> _iv;
  List<int> _data;
  List<int> _authenTag;
  List<int> _sign;

  Cipher.initDefault()
      : _msgID = 0,
        _msgType = MessageType.single,
        _msgTag = 0,
        _isFirst = false,
        _isLast = false,
        _isRequest = false,
        _isEncrypted = false,
        _name = "",
        _iv = List.empty(),
        _data = List.empty(),
        _authenTag = List.empty(),
        _sign = List.empty();

  Cipher({
    required int msgID,
    required MessageType msgType,
    required int msgTag,
    required bool isFirst,
    required bool isLast,
    required bool isRequest,
    required bool isEncrypted,
    required String name,
    required List<int> iv,
    required List<int> data,
    required List<int> authenTag,
    required List<int> sign,
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

  void setData(List<int> data) {
    this._data = data;
  }

  void setIsEncrypted(bool isEncrypted) {
    this._isEncrypted = isEncrypted;
  }

  void setIV(List<int> iv) {
    this._iv = iv;
  }

  void setAuthenTag(List<int> authenTag) {
    this._authenTag = authenTag;
  }

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

  List<int> getIV() {
    return this._iv;
  }

  List<int> getAuthenTag() {
    return this._authenTag;
  }

  List<int> getData() {
    return this._data;
  }

  List<int> getSign() {
    return this._sign;
  }

  Result<List<int>> intoBytes() {
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

  Result<List<int>> getRawBytes() {
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

  Result<List<int>> getAad() {
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
        data: Cipher.initDefault(),
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
          data: Cipher.initDefault(),
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
        data: Cipher.initDefault(),
      );
    }
    if (lenBuffer < (fixedLen + lenName)) {
      return Result(
        errorCode: ErrorCode.invalidBytes,
        data: Cipher.initDefault(),
      );
    }

    // Parse AUTHEN_TAG, IV
    List<int> authenTag;
    List<int> iv;
    List<int> sign;
    if (isEncrypted) {
      var posIV = posAuthenTag + Constant.lengthAuthenTag;
      authenTag = buffer
          .asUint8List(posAuthenTag, Constant.lengthAuthenTag)
          .toList(growable: false);
      iv = buffer.asUint8List(posIV, Constant.lengthIV).toList(growable: false);
      sign = List.empty();
    } else {
      var posSign = fixedLen;
      fixedLen += Constant.lengthSign;
      if (lenBuffer < (fixedLen + lenName)) {
        return Result(
          errorCode: ErrorCode.invalidBytes,
          data: Cipher.initDefault(),
        );
      }
      authenTag = List.empty();
      iv = List.empty();
      sign = buffer
          .asUint8List(posSign, Constant.lengthSign)
          .toList(growable: false);
    }

    // Parse name
    var posData = fixedLen + lenName;
    var name = String.fromCharCodes(buffer.asUint8List(fixedLen, lenName));

    // Parse data
    var lenData = lenBuffer - posData;
    List<int> data;
    if (lenData > 0) {
      data = buffer.asUint8List(posData).toList(growable: false);
    } else {
      data = List.empty();
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

  static Result<List<int>> buildRawBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isEncrypted,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    List<int> data,
  ) {
    var lenName = name.length;
    if (lenName == 0 || lenName > MaxConnectionNameLength) {
      return Result(
        errorCode: ErrorCode.invalidConnectionName,
        data: List.empty(),
      );
    }
    var lenData = data.length;

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

    var buffer = List.filled(fixedLen + lenName + lenData, 0, growable: false);
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

  static Result<List<int>> buildAad(
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
        data: List.empty(),
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

    var buffer = List.filled(fixedLen + lenName, 0, growable: false);
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

  static Result<List<int>> buildCipherBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    List<int> iv,
    List<int> data,
    List<int> authenTag,
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
      List<int>.empty(),
    );
  }

  static Result<List<int>> buildNoCipherBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    List<int> data,
    List<int> sign,
  ) {
    var empty = List<int>.empty();
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

  static Result<List<int>> buildBytes(
    int msgID,
    int msgTag,
    MessageType msgType,
    bool isEncrypted,
    bool isFirst,
    bool isLast,
    bool isRequest,
    String name,
    List<int> iv,
    List<int> data,
    List<int> authenTag,
    List<int> sign,
  ) {
    var lenName = name.length;
    if (lenName == 0 || lenName > MaxConnectionNameLength) {
      return Result(
        errorCode: ErrorCode.invalidConnectionName,
        data: List.empty(),
      );
    }

    var lenIV = iv.length;
    var lenAuthenTag = authenTag.length;
    var lenSign = sign.length;
    if (isEncrypted) {
      if (lenIV != Constant.lengthIV ||
          lenAuthenTag != Constant.lengthAuthenTag) {
        return Result(
          errorCode: ErrorCode.invalidBytes,
          data: List.empty(),
        );
      }
      lenSign = 0;
    } else {
      if (lenSign != Constant.lengthSign) {
        return Result(
          errorCode: ErrorCode.invalidBytes,
          data: List.empty(),
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

    var lenData = data.length;
    var lenBuffer =
        fixedLen + lenAuthenTag + lenIV + lenSign + lenName + lenData;
    var buffer = List.filled(lenBuffer, 0, growable: false);
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
