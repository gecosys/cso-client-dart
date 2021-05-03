// MessageType is type of message (data) in Cipher
class MessageType {
  final int _value;

  const MessageType._internal(this._value);

  toString() => 'MessageType.$_value';
  toValue() => this._value;

  static parse(int value) {
    switch (value) {
      case 0x02:
        return MessageType.activation;
      case 0x03:
        return MessageType.single;
      case 0x04:
        return MessageType.group;
      case 0x05:
        return MessageType.singleCached;
      case 0x06:
        return MessageType.groupCached;
      case 0x07:
        return MessageType.done;
      default:
        return MessageType.unknown;
    }
  }

  static const unknown = const MessageType._internal(0x00);

  // Activation is type of activation message
  static const activation = const MessageType._internal(0x02);

  // Single is type of single message (message sent to another connection)
  static const single = const MessageType._internal(0x03);

  // Group is type of group message (message sent to a group of connections)
  static const group = const MessageType._internal(0x04);

  // SingleCached is type of single message (message sent to another connection and cached on system)
  static const singleCached = const MessageType._internal(0x05);

  // GroupCached is type of group message (message sent to a group of connections and cached on system)
  static const groupCached = const MessageType._internal(0x06);

  // Done is type of done message
  static const done = const MessageType._internal(0x07);
}
