import 'dart:ffi';

import 'dart:typed_data';

import 'package:cso_client_flutter/message/result.dart';

import 'define.dart';

class ReadyTicket {
  final bool _isReady;
  final int _idxRead;
  final int _maskRead;
  final int _idxWrite;

  ReadyTicket({
    required bool isReady,
    required int idxRead,
    required int maskRead,
    required int idxWrite,
  })   : _isReady = isReady,
        _idxRead = idxRead,
        _maskRead = maskRead,
        _idxWrite = idxWrite;

  bool getIsReady() {
    return this._isReady;
  }

  BigInt getIdxRead() {
    return BigInt.from(this._idxRead).toUnsigned(64);
  }

  BigInt getMaskRead() {
    return BigInt.from(this._maskRead).toUnsigned(32);
  }

  BigInt getIdxWrite() {
    return BigInt.from(this._idxWrite).toUnsigned(64);
  }

  static ReadyTicket newDefault() {
    return ReadyTicket(
      isReady: false,
      idxRead: 0,
      maskRead: 0,
      idxWrite: 0,
    );
  }

  // ParseBytes converts bytes to ReadyTicket
  // Flag is_ready: 1 byte
  // Idx Read: 8 bytes
  // Mark Read: 4 bytes
  // Idx Write: 8 bytes
  static Result<ReadyTicket> parseBytes(ByteBuffer buffer) {
    var lenBuffer = buffer.lengthInBytes;
    if (lenBuffer != 21) {
      return Result(
        errorCode: ErrorCode.invalidBytes,
        data: ReadyTicket.newDefault(),
      );
    }
    var bytes = buffer.asByteData(0, lenBuffer);
    var isReady = bytes.getUint8(0) == 1;
    var idxRead = bytes.getUint64(1, Endian.little);
    var maskRead = bytes.getUint32(9, Endian.little);
    var idxWrite = bytes.getUint64(13, Endian.little);
    return Result(
      errorCode: ErrorCode.success,
      data: ReadyTicket(
        isReady: isReady,
        idxRead: idxRead,
        maskRead: maskRead,
        idxWrite: idxWrite,
      ),
    );
  }
}