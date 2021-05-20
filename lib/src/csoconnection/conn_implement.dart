import 'dart:io';
import 'dart:math';

import 'conn_interface.dart';
import 'conn_status.dart';

import '../message/define.dart';

class Connection implements IConnection {
  // HeaderSize is size of header
  static const headerSize = 2;

// BufferSize is size of buffer or body
  static const bufferSize = 1204;

  Status _status = Status.prepare;
  Socket? _clienSocket;

  Future<int> _connect(String address) async {
    if (this._status != Status.prepare && this._clienSocket != null) {
      this._status = Status.prepare;
      this._clienSocket?.close();
    }

    this._status = Status.connecting;

    final strs = address.split(":");
    if (strs.length != 2) {
      return ErrorCode.invalidAddress;
    }
    this._clienSocket = await Socket.connect(
      strs[0],
      int.parse(strs[1]),
      timeout: Duration(seconds: 30),
    );
    this._status = Status.connected;
    return ErrorCode.success;
  }

  Future<void> close() async {
    await this._clienSocket?.close();
  }

  Future<int> listen(
    String address, {
    required void onMessage(List<int> msg),
    required void onDisconnected(),
  }) async {
    var posBuffer = 0;
    var nextPosBuffer = 0;
    var lenHeader = 0;
    var lenBody = 0;
    var lenBuffer = 0;
    var lenMessage = 0;
    var header = List<int>.filled(Connection.headerSize, 0, growable: false);
    var body = List<int>.filled(Connection.bufferSize, 0, growable: false);

    final errorCode = await this._connect(address);
    if (errorCode != ErrorCode.success) {
      return errorCode;
    }

    if (this._clienSocket == null) {
      return ErrorCode.errorConnection;
    }

    this._clienSocket?.listen(
        (buffer) {
          posBuffer = 0;
          lenBuffer = buffer.lengthInBytes;
          while (posBuffer < lenBuffer) {
            // Read header
            if (lenMessage == 0) {
              nextPosBuffer = min(
                posBuffer + Connection.headerSize - lenHeader,
                lenBuffer,
              );
              header.setAll(
                  lenHeader, buffer.getRange(posBuffer, nextPosBuffer));
              lenHeader += nextPosBuffer - posBuffer;
              posBuffer = nextPosBuffer;
              if (lenHeader == Connection.headerSize) {
                lenMessage = header[1] << 8 | header[0];
                lenBody = 0;
              }
              continue;
            }

            if (lenMessage <= 0 || lenMessage > Connection.bufferSize) {
              lenHeader = 0;
              lenMessage = 0;
              posBuffer += lenMessage;
              continue;
            }

            // Read body
            nextPosBuffer = min(
              posBuffer + (lenMessage - lenBody),
              lenBuffer,
            );
            body.setAll(lenBody, buffer.getRange(posBuffer, nextPosBuffer));
            lenBody += nextPosBuffer - posBuffer;
            posBuffer = nextPosBuffer;
            if (lenBody != lenMessage) {
              continue;
            }
            onMessage(body.getRange(0, lenBody).toList(growable: false));
            lenMessage = 0;
            lenHeader = 0;
          }
        },
        onError: (e) {},
        onDone: () {
          this._status = Status.disconnected;
          onDisconnected();
        });
    return ErrorCode.success;
  }

  Future<int> sendMessage(List<int> data) async {
    if (this._status != Status.connected) {
      return ErrorCode.errorConnection;
    }

    // Build formated data
    final lenBytes = data.length;
    final lenBuffer = 2 + lenBytes;
    final buffer = List<int>.filled(lenBuffer, 0, growable: false);
    final valLenBytes = BigInt.from(lenBytes);
    buffer[0] = valLenBytes.toUnsigned(8).toInt();
    buffer[1] = (valLenBytes >> 8).toUnsigned(8).toInt();
    buffer.setAll(2, data);

    // Send message
    this._clienSocket?.add(buffer);
    // await this._clienSocket?.flush();
    return ErrorCode.success;
  }
}
