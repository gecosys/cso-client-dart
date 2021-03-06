import 'queue_entity.dart';

abstract class IQueue {
  bool pushMessage(ItemQueue item);
  ItemQueue? nextMessage();
  void clearMessage(BigInt msgID);
}
