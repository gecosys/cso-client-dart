import 'package:cso_client_flutter/csoproxy/proxy_message.dart';
import 'package:cso_client_flutter/message/result.dart';

abstract class IProxy {
  Future<Result<ServerKey>> exchangeKey();
  Future<Result<ServerTicket>> registerConnection(ServerKey serverKey);
}
