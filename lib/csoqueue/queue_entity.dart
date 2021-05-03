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
  int _numberRetry;
  int _timestamp;

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
        _numberRetry = numberRetry,
        _timestamp = timestamp;

  void setNumberRetry(int numberRetry) {
    this._numberRetry = numberRetry;
  }

  void setTimestamp(int timestamp) {
    this._timestamp = timestamp;
  }

  BigInt getMsgID() {
    return BigInt.from(this._msgID).toUnsigned(64);
  }

  BigInt getMsgTag() {
    return BigInt.from(this._msgTag).toUnsigned(64);
  }

  String getRecvName() {
    return this._recvName;
  }

  List<int> getContent() {
    return this._content;
  }

  bool getIsEncrypted() {
    return this._isEncrypted;
  }

  bool getIsCached() {
    return this._isCached;
  }

  bool getIsFirst() {
    return this._isFirst;
  }

  bool getIsLast() {
    return this._isLast;
  }

  bool getIsRequest() {
    return this._isRequest;
  }

  bool getIsGroup() {
    return this._isGroup;
  }

  int getNumberRetry() {
    return this._numberRetry;
  }

  BigInt getTimestamp() {
    return BigInt.from(this._timestamp).toUnsigned(64);
  }
}
