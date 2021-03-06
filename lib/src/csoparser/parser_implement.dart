import 'dart:typed_data';

import 'parser_interface.dart';

import '../message/cipher.dart';
import '../message/define.dart';
import '../message/result.dart';
import '../message/type.dart';
import '../utils/aes.dart';
import '../utils/hmac.dart';

class Parser implements IParser {
  List<int> _secretKey = [];

  set secretKey(List<int> value) => _secretKey = value;

  Future<Result<Cipher>> parseReceivedMessage(List<int> content) async {
    final msg = Cipher.parseBytes(Uint8List.fromList(content).buffer);
    if (msg.errorCode != ErrorCode.success) {
      return Result(errorCode: msg.errorCode, data: Cipher.initDefault());
    }

    if (msg.data.isEncrypted == false) {
      final rawBytes = msg.data.getRawBytes();
      if (rawBytes.errorCode != ErrorCode.success) {
        return Result(
            errorCode: rawBytes.errorCode, data: Cipher.initDefault());
      }
      final isValid = await HMAC.validateHMAC(
        _secretKey,
        rawBytes.data,
        msg.data.sign,
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

    msg.data.data = await AES.decrypt(
      _secretKey,
      msg.data.iv,
      msg.data.authenTag,
      msg.data.data,
      aad.data,
    );
    msg.data.isEncrypted = false;
    msg.data.iv = [];
    msg.data.authenTag = [];
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
    final secretBox = await AES.encrypt(_secretKey, ticketBytes, aad.data);
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
    final msgType = _getMessagetype(false, isCached);
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
      final sign = await HMAC.calcHMAC(_secretKey, rawBytes.data);
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
    final secretBox = await AES.encrypt(_secretKey, content, aad.data);
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
    final msgType = _getMessagetype(true, isCached);
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
      final sign = await HMAC.calcHMAC(_secretKey, rawBytes.data);
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
    final secretBox = await AES.encrypt(_secretKey, content, aad.data);
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
