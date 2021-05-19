// ItemQueue is an item in Queue
class ItemQueue {
  final int _msgID;
  final int _msgTag;
  final String _recvName;
  final List<int> _content;
  final bool _isEncrypted;
  final bool _isCached;
  final bool _isFirst;
  final bool _isLast;
  final bool _isRequest;
  final bool _isGroup;
  int _timestamp;
  int numberRetry;

  ItemQueue({
    required int msgID,
    required int msgTag,
    required String recvName,
    required List<int> content,
    required bool isEncrypted,
    required bool isCached,
    required bool isFirst,
    required bool isLast,
    required bool isRequest,
    required bool isGroup,
    required int numberRetry,
    required int timestamp,
  })   : _msgID = msgID,
        _msgTag = msgTag,
        _recvName = recvName,
        _content = content,
        _isEncrypted = isEncrypted,
        _isCached = isCached,
        _isFirst = isFirst,
        _isLast = isLast,
        _isRequest = isRequest,
        _isGroup = isGroup,
        this.numberRetry = numberRetry,
        _timestamp = timestamp;

  set timestamp(BigInt value) => _timestamp = value.toInt();

  BigInt get msgID => BigInt.from(this._msgID).toUnsigned(64);
  BigInt get msgTag => BigInt.from(this._msgTag).toUnsigned(64);

  String get recvName => _recvName;
  List<int> get content => _content;

  bool get isEncrypted => _isEncrypted;
  bool get isCached => _isCached;
  bool get isFirst => _isFirst;
  bool get isLast => _isLast;
  bool get isRequest => _isRequest;
  bool get isGroup => _isGroup;

  BigInt get timestamp => BigInt.from(this._timestamp).toUnsigned(64);
}
