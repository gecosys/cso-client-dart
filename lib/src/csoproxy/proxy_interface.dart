import 'proxy_message.dart';

import '../message/result.dart';

abstract class IProxy {
  Future<Result<ServerKey>> exchangeKey();
  Future<Result<ServerTicket>> registerConnection(ServerKey serverKey);
}
