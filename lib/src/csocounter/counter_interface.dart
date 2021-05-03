abstract class ICounter {
  int nextWriteIndex();
  void markReadUnused(BigInt idx);
  bool markReadDone(BigInt idx);
}
