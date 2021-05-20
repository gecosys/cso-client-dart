import 'counter_interface.dart';

class Counter implements ICounter {
  static final numberBits = BigInt.from(32);

  BigInt _writeIndex;
  BigInt _minReadIdx;
  int _maskReadBits;

  Counter({
    required BigInt writeIndex,
    required BigInt minReadIdx,
    required int maskReadBits,
  })   : _writeIndex = writeIndex - BigInt.one,
        _minReadIdx = minReadIdx,
        _maskReadBits = maskReadBits;

  int nextWriteIndex() {
    _writeIndex += BigInt.one;
    return _writeIndex.toUnsigned(64).toInt();
  }

  void markReadUnused(BigInt idx) {
    if (idx < _minReadIdx) {
      return;
    }
    if (idx >= (_minReadIdx + Counter.numberBits)) {
      return;
    }
    final mask = 1 << (idx - _minReadIdx).toUnsigned(32).toInt();
    _maskReadBits &= ~mask;
  }

  bool markReadDone(BigInt idx) {
    if (idx < _minReadIdx) {
      return false;
    }
    if (idx >= (_minReadIdx + Counter.numberBits)) {
      _minReadIdx += Counter.numberBits;
      _maskReadBits = 0;
    }
    final mask = 1 << (idx - _minReadIdx).toUnsigned(32).toInt();
    if ((_maskReadBits & mask) != 0) {
      return false;
    }
    _maskReadBits |= mask;
    return true;
  }
}
