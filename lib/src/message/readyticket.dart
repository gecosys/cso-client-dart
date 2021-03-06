import 'dart:typed_data';

import 'define.dart';
import 'result.dart';

class ReadyTicket {
  final bool _isReady;
  final int _idxRead;
  final int _maskRead;
  final int _idxWrite;

  ReadyTicket.initDefault()
      : _isReady = false,
        _idxRead = 0,
        _maskRead = 0,
        _idxWrite = 0;

  ReadyTicket({
    required bool isReady,
    required int idxRead,
    required int maskRead,
    required int idxWrite,
  })   : _isReady = isReady,
        _idxRead = idxRead,
        _maskRead = maskRead,
        _idxWrite = idxWrite;

  bool get isReady => _isReady;
  BigInt get idxRead => BigInt.from(_idxRead).toUnsigned(64);
  BigInt get maskRead => BigInt.from(_maskRead).toUnsigned(32);
  BigInt get idxWrite => BigInt.from(_idxWrite).toUnsigned(64);

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
        data: ReadyTicket.initDefault(),
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
