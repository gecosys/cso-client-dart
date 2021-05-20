// Status is status of connection
class Status {
  final int _value;

  const Status._internal(this._value);

  toString() => 'Status.$_value';
  toValue() => _value;

  static parse(int value) {
    switch (value) {
      case 0x00:
        return Status.prepare;
      case 0x01:
        return Status.connecting;
      case 0x02:
        return Status.connected;
      case 0x03:
        return Status.disconnected;
      default:
        return Status.unknown;
    }
  }

  static const unknown = const Status._internal(0xFF);

  // Prepare is status when the connection is setting up.
  static const prepare = const Status._internal(0x00);

  // Connecting is status when the connection is connecting to server.
  static const connecting = const Status._internal(0x01);

  // Connected is status when the connection connected to server.
  static const connected = const Status._internal(0x02);

  // Disconnected is status when the connection closed.
  static const disconnected = const Status._internal(0x03);
}
