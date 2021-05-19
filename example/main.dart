import 'dart:convert';

import 'package:gecosys_cso_client/gecosys_cso_client.dart';

void main() async {
  final bufferSize = 1024;

  // Read config from file
  final config = await Config.fromFile("cso_key.json");

  // Init connector
  // final connector = Connector(
  //   bufferSize,
  //   queue: Queue(cap: bufferSize),
  //   parser: Parser(),
  //   proxy: Proxy(config),
  // );
  final connector = Connector.initDefault(bufferSize, config);

  // Open a connection to the Cloud Socket system
  connector.listen((sender, data) async {
    print('Received message from $sender');
    print(utf8.decode(data));
    return Future.value(ErrorCode.success);
  });

  // Send a message to the connection itself every 1 second
  loopSendMessage(config.connName, connector);
}

void loopSendMessage(String receiver, IConnector connector) {
  Future.delayed(Duration(seconds: 1), () async {
    final errorCode = await connector.sendMessage(
      receiver,
      "Goldeneye ECO".codeUnits,
      true,
      false,
    );
    if (errorCode != ErrorCode.success) {
      print("Send message failed");
    }
    loopSendMessage(receiver, connector);
  });
}
