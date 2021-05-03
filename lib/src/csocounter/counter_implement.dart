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
    this._writeIndex += BigInt.one;
    return this._writeIndex.toUnsigned(64).toInt();
  }

  void markReadUnused(BigInt idx) {
    if (idx < this._minReadIdx) {
      return;
    }
    if (idx >= (this._minReadIdx + Counter.numberBits)) {
      return;
    }
    final mask = 1 << (idx - this._minReadIdx).toUnsigned(32).toInt();
    this._maskReadBits &= ~mask;
  }

  bool markReadDone(BigInt idx) {
    if (idx < this._minReadIdx) {
      return false;
    }
    if (idx >= (this._minReadIdx + Counter.numberBits)) {
      this._minReadIdx += Counter.numberBits;
      this._maskReadBits = 0;
    }
    final mask = 1 << (idx - this._minReadIdx).toUnsigned(32).toInt();
    if ((this._maskReadBits & mask) != 0) {
      return false;
    }
    this._maskReadBits |= mask;
    return true;
  }
}
