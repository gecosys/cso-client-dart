A library for connecting to the Cloud Socket system.

## Introduce Cloud Socket
Connectivity is the key word for Internet of Things.

Cloud Socket is a connection platform to manage connections and data routing between clients and servers in IoT projects. The platform is robust, flexible, and scalable to accommodate large-scale connections, while securing, queuing and preventing data from being lost on network or offline destination connection.

## Usage
```dart
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
  connector.listen((sender, data) {
    print('Received message from $sender');
    print(utf8.decode(data));
    return ErrorCode.success;
  });

  // Send a message to the connection itself every 1 second
  loopSendMessage(config.getConnectionName(), connector);
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
```

## Website
https://cso.goldeneyetech.com.vn
