import 'dart:ffi';
import 'dart:typed_data';

import 'package:cso_client_flutter/cso/message/define.dart';
import 'package:cso_client_flutter/cso/message/result.dart';
import 'package:flutter/material.dart';

class Ticket {
  final int _id;
  final Uint8List _token;

  Ticket({
    required int id,
    required Uint8List token,
  })   : _id = id,
        _token = token;

  BigInt getID() {
    return BigInt.from(this._id).toUnsigned(16);
  }

  Uint8List getToken() {
    return this._token;
  }

  static Ticket newDefault() {
    return Ticket(
      id: 0,
      token: Uint8List(0),
    );
  }

  static Result<Ticket> parseBytes(ByteBuffer buffer) {
    if (buffer.lengthInBytes != 34) {
      return Result(
        errorCode: ErrorCode.invalidBytes,
        data: Ticket.newDefault(),
      );
    }
    var bytes = buffer.asByteData(0);
    return Result(
      errorCode: ErrorCode.success,
      data: Ticket(
        id: bytes.getUint16(0),
        token: buffer.asUint8List(2),
      ),
    );
  }

  static Result<Uint8List> buildBytes(int id, Uint8List token) {
    if (token.lengthInBytes != 32) {
      return Result(
        errorCode: ErrorCode.invalidToken,
        data: Uint8List(0),
      );
    }
    var valID = BigInt.from(id).toUnsigned(16);
    var buffer = Uint8List(34);
    buffer[0] = valID.toUnsigned(8).toInt();
    buffer[1] = (valID >> 8).toUnsigned(8).toInt();
    buffer.setAll(2, token);
    return Result(
      errorCode: ErrorCode.success,
      data: buffer,
    );
  }
}
