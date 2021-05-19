import 'queue_entity.dart';
import 'queue_interface.dart';

class Queue implements IQueue {
  final int _cap;
  int _len;
  List<ItemQueue?> _items;

  Queue({required int cap})
      : _cap = cap,
        _len = 0,
        _items = List.filled(cap, null, growable: false);

  bool pushMessage(ItemQueue item) {
    if (this._len == this._cap) {
      return false;
    }
    for (var idx = 0; idx < this._cap; ++idx) {
      if (this._items[idx] == null) {
        ++this._len;
        this._items[idx] = item;
        return true;
      }
    }
    return false;
  }

  ItemQueue? nextMessage() {
    final limitSecond = BigInt.from(3);
    final now = BigInt.from(DateTime.now().second).toUnsigned(64);
    ItemQueue? nextItem;
    for (var idx = 0; idx < this._cap; ++idx) {
      final item = this._items[idx];
      if (item == null) {
        continue;
      }
      if (nextItem == null && (now - item.timestamp) >= limitSecond) {
        nextItem = item;
        item.timestamp = now;
        item.numberRetry = item.numberRetry - 1;
      }
      if (item.numberRetry == 0) {
        this._items[idx] = null;
        --this._len;
      }
    }
    return nextItem;
  }

  void clearMessage(BigInt msgID) {
    for (var idx = 0; idx < this._cap; ++idx) {
      final item = this._items[idx];
      if (item != null && item.msgID == msgID) {
        this._items[idx] = null;
        --this._len;
      }
    }
  }
}
