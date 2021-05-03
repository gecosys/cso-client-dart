import 'dart:typed_data';

import 'package:cso_client_flutter/csoparser/parser_interface.dart';
import 'package:cso_client_flutter/message/cipher.dart';
import 'package:cso_client_flutter/message/define.dart';
import 'package:cso_client_flutter/message/result.dart';
import 'package:cso_client_flutter/message/type.dart';
import 'package:cso_client_flutter/utils/aes.dart';
import 'package:cso_client_flutter/utils/hmac.dart';

class Parser implements IParser {
  List<int> _secretKey = [];

  void setSecretKey(List<int> secretKey) {
    this._secretKey = secretKey;
  }

  Future<Result<Cipher>> parseReceivedMessage(List<int> content) async {
    final msg = Cipher.parseBytes(Uint8List.fromList(content).buffer);
    if (msg.errorCode != ErrorCode.success) {
      return Result(errorCode: msg.errorCode, data: Cipher.initDefault());
    }

    if (msg.data.getIsEncrypted() == false) {
      final rawBytes = msg.data.getRawBytes();
      if (rawBytes.errorCode != ErrorCode.success) {
        return Result(
            errorCode: rawBytes.errorCode, data: Cipher.initDefault());
      }
      final isValid = await HMAC.validateHMAC(
        this._secretKey,
        rawBytes.data,
        msg.data.getSign(),
      );
      if (isValid == false) {
        return Result(
          errorCode: ErrorCode.invalidSignature,
          data: Cipher.initDefault(),
        );
      }
      return msg;
    }

    final aad = msg.data.getAad();
    if (aad.errorCode != ErrorCode.success) {
      return Result(errorCode: aad.errorCode, data: Cipher.initDefault());
    }

    msg.data.setData(await AES.decrypt(
      this._secretKey,
      msg.data.getIV(),
      msg.data.getAuthenTag(),
      msg.data.getData(),
      aad.data,
    ));
    msg.data.setIsEncrypted(false);
    msg.data.setIV([]);
    msg.data.setAuthenTag([]);
    return msg;
  }

  Future<Result<List<int>>> buildActivateMessage(
    int ticketID,
    List<int> ticketBytes,
  ) async {
    final name = ticketID.toString();
    final aad = Cipher.buildAad(
      0,
      0,
      MessageType.activation,
      true,
      true,
      true,
      true,
      name,
    );
    if (aad.errorCode != ErrorCode.success) {
      return Result(errorCode: aad.errorCode, data: List.empty());
    }
    final secretBox = await AES.encrypt(this._secretKey, ticketBytes, aad.data);
    return Cipher.buildCipherBytes(
      0,
      0,
      MessageType.activation,
      true,
      true,
      true,
      name,
      secretBox.nonce,
      secretBox.cipherText,
      secretBox.mac.bytes,
    );
  }

  Future<Result<List<int>>> buildMessage(
    int msgID,
    int msgTag,
    String recvName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
    bool isFirst,
    bool isLast,
    bool isRequest,
  ) async {
    final msgType = this._getMessagetype(false, isCached);
    if (!isEncrypted) {
      final rawBytes = Cipher.buildRawBytes(
        msgID,
        msgTag,
        msgType,
        false,
        isFirst,
        isLast,
        isRequest,
        recvName,
        content,
      );
      if (rawBytes.errorCode != ErrorCode.success) {
        return Result(errorCode: rawBytes.errorCode, data: List.empty());
      }
      final sign = await HMAC.calcHMAC(this._secretKey, rawBytes.data);
      return Cipher.buildNoCipherBytes(
        msgID,
        msgTag,
        msgType,
        isFirst,
        isLast,
        isRequest,
        recvName,
        content,
        sign,
      );
    }

    final aad = Cipher.buildAad(
      msgID,
      msgTag,
      msgType,
      true,
      isFirst,
      isLast,
      isRequest,
      recvName,
    );
    if (aad.errorCode != ErrorCode.success) {
      return Result(errorCode: aad.errorCode, data: List.empty());
    }
    final secretBox = await AES.encrypt(this._secretKey, content, aad.data);
    return Cipher.buildCipherBytes(
      msgID,
      msgTag,
      msgType,
      isFirst,
      isLast,
      isRequest,
      recvName,
      secretBox.nonce,
      secretBox.cipherText,
      secretBox.mac.bytes,
    );
  }

  Future<Result<List<int>>> buildGroupMessage(
    int msgID,
    int msgTag,
    String groupName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
    bool isFirst,
    bool isLast,
    bool isRequest,
  ) async {
    final msgType = this._getMessagetype(true, isCached);
    if (!isEncrypted) {
      final rawBytes = Cipher.buildRawBytes(
        msgID,
        msgTag,
        msgType,
        false,
        isFirst,
        isLast,
        isRequest,
        groupName,
        content,
      );
      if (rawBytes.errorCode != ErrorCode.success) {
        return Result(errorCode: rawBytes.errorCode, data: List.empty());
      }
      final sign = await HMAC.calcHMAC(this._secretKey, rawBytes.data);
      return Cipher.buildNoCipherBytes(
        msgID,
        msgTag,
        msgType,
        isFirst,
        isLast,
        isRequest,
        groupName,
        content,
        sign,
      );
    }

    final aad = Cipher.buildAad(
      msgID,
      msgTag,
      msgType,
      true,
      isFirst,
      isLast,
      isRequest,
      groupName,
    );
    if (aad.errorCode != ErrorCode.success) {
      return Result(errorCode: aad.errorCode, data: List.empty());
    }
    final secretBox = await AES.encrypt(this._secretKey, content, aad.data);
    return Cipher.buildCipherBytes(
      msgID,
      msgTag,
      msgType,
      isFirst,
      isLast,
      isRequest,
      groupName,
      secretBox.nonce,
      secretBox.cipherText,
      secretBox.mac.bytes,
    );
  }

  MessageType _getMessagetype(bool isGroup, bool isCached) {
    if (isGroup) {
      if (isCached) {
        return MessageType.groupCached;
      }
      return MessageType.group;
    }
    if (isCached) {
      return MessageType.singleCached;
    }
    return MessageType.single;
  }
}
