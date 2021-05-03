import 'dart:typed_data';

import 'package:cso_client_flutter/src/message/define.dart';
import 'package:cso_client_flutter/src/message/result.dart';

class Ticket {
  final int _id;
  final List<int> _token;

  Ticket.initDefault()
      : _id = 0,
        _token = List.empty();

  Ticket({
    required int id,
    required List<int> token,
  })   : _id = id,
        _token = token;

  BigInt getID() {
    return BigInt.from(this._id).toUnsigned(16);
  }

  List<int> getToken() {
    return this._token;
  }

  // ParseBytes converts bytes to Ticket
  // ID: 2 bytes
  // Token: next 32 bytes
  static Result<Ticket> parseBytes(ByteBuffer buffer) {
    if (buffer.lengthInBytes != 34) {
      return Result(
        errorCode: ErrorCode.invalidBytes,
        data: Ticket.initDefault(),
      );
    }
    var bytes = buffer.asByteData(0);
    return Result(
      errorCode: ErrorCode.success,
      data: Ticket(
        id: bytes.getUint16(0),
        token: buffer.asUint8List(2).toList(growable: false),
      ),
    );
  }

  static Result<List<int>> buildBytes(int id, List<int> token) {
    if (token.length != 32) {
      return Result(
        errorCode: ErrorCode.invalidToken,
        data: List.empty(),
      );
    }
    var valID = BigInt.from(id).toUnsigned(16);
    var buffer = List.filled(34, 0, growable: false);
    buffer[0] = valID.toUnsigned(8).toInt();
    buffer[1] = (valID >> 8).toUnsigned(8).toInt();
    buffer.setAll(2, token);
    return Result(
      errorCode: ErrorCode.success,
      data: buffer,
    );
  }
}
