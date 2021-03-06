import 'dart:typed_data';

import 'connector_interface.dart';

import '../config/config.dart';
import '../csoconnection/conn_implement.dart';
import '../csoconnection/conn_interface.dart';
import '../csocounter/counter_implement.dart';
import '../csocounter/counter_interface.dart';
import '../csoparser/parser_implement.dart';
import '../csoparser/parser_interface.dart';
import '../csoproxy/proxy_implement.dart';
import '../csoproxy/proxy_interface.dart';
import '../csoproxy/proxy_message.dart';
import '../csoqueue/queue_entity.dart';
import '../csoqueue/queue_implement.dart';
import '../csoqueue/queue_interface.dart';
import '../message/define.dart';
import '../message/readyticket.dart';
import '../message/result.dart';
import '../message/type.dart';

class Connector implements IConnector {
  bool _isStopped = false;
  bool _isRunning = false;
  bool _isActivated = false;
  ICounter? _counter;
  IConnection _conn;
  IQueue _queueMessages;
  IParser _parser;
  IProxy _proxy;

  Connector.initDefault(int bufferSize, IConfig conf)
      : _counter = null,
        _conn = Connection(),
        _queueMessages = Queue(cap: bufferSize),
        _parser = Parser(),
        _proxy = Proxy(conf);

  Connector(
    int bufferSize, {
    required IQueue queue,
    required IParser parser,
    required Proxy proxy,
  })   : _counter = null,
        _conn = Connection(),
        _queueMessages = queue,
        _parser = parser,
        _proxy = proxy;

  Future<void> close() async {
    if (_isStopped) {
      return;
    }
    _isStopped = true;
    await _conn.close();
  }

  void listen(Future<int> cb(String sender, List<int> data)) {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    _loopReconnect(cb);
    _loopRetrySendMessage();
  }

  Future<int> sendMessage(
    String recvName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
  ) async {
    if (_isActivated == false || _isStopped) {
      return ErrorCode.errorConnection;
    }
    final msg = await _parser.buildMessage(
      0,
      0,
      recvName,
      content,
      isEncrypted,
      isCached,
      true,
      true,
      true,
    );
    if (msg.errorCode != ErrorCode.success) {
      return msg.errorCode;
    }
    return _conn.sendMessage(msg.data);
  }

  Future<int> sendGroupMessage(
    String groupName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
  ) async {
    if (_isActivated == false || _isStopped) {
      return ErrorCode.errorConnection;
    }
    final msg = await _parser.buildGroupMessage(
      0,
      0,
      groupName,
      content,
      isEncrypted,
      isCached,
      true,
      true,
      true,
    );
    if (msg.errorCode != ErrorCode.success) {
      return msg.errorCode;
    }
    return _conn.sendMessage(msg.data);
  }

  Future<int> sendMessageAndRetry(
    String recvName,
    List<int> content,
    bool isEncrypted,
    int numberRetry,
  ) async {
    if (_isActivated == false || _isStopped) {
      return ErrorCode.errorConnection;
    }
    final isSuccess = _queueMessages.pushMessage(
      ItemQueue(
        msgID: _counter?.nextWriteIndex() ?? 0,
        msgTag: 0,
        recvName: recvName,
        content: content,
        isEncrypted: isEncrypted,
        isCached: false,
        isFirst: true,
        isLast: true,
        isRequest: true,
        isGroup: false,
        numberRetry: numberRetry + 1,
        timestamp: 0,
      ),
    );
    return isSuccess ? ErrorCode.success : ErrorCode.errorQueueFull;
  }

  Future<int> sendGroupMessageAndRetry(
    String groupName,
    List<int> content,
    bool isEncrypted,
    int numberRetry,
  ) async {
    if (_isActivated == false || _isStopped) {
      return ErrorCode.errorConnection;
    }
    final isSuccess = _queueMessages.pushMessage(
      ItemQueue(
        msgID: _counter?.nextWriteIndex() ?? 0,
        msgTag: 0,
        recvName: groupName,
        content: content,
        isEncrypted: isEncrypted,
        isCached: false,
        isFirst: true,
        isLast: true,
        isRequest: true,
        isGroup: true,
        numberRetry: numberRetry + 1,
        timestamp: 0,
      ),
    );
    return isSuccess ? ErrorCode.success : ErrorCode.errorQueueFull;
  }

  void _loopReconnect(Future<int> cb(String sender, List<int> data)) {
    Future.delayed(const Duration(seconds: 1), () async {
      if (_isStopped) {
        return;
      }
      final serverTicket = await _prepare();
      if (serverTicket.errorCode != ErrorCode.success) {
        _loopReconnect(cb);
        return;
      }

      var isDisconnected = [false]; // use list to use reference
      _isActivated = false;
      _loopActivateConnection(
        isDisconnected,
        serverTicket.data.ticketID.toInt(),
        serverTicket.data.ticketBytes,
      );

      // Connect to Cloud Socket system
      _parser.secretKey = serverTicket.data.serverSecretKey;
      _conn.listen(
        serverTicket.data.hubAddress,
        onMessage: (msg) => _processMessage(msg, cb),
        onDisconnected: () {
          isDisconnected[0] = true;
          _loopReconnect(cb);
        },
      );
    });
  }

  void _loopActivateConnection(
    List<bool> isDisconnected,
    int ticketID,
    List<int> ticketBytes,
  ) {
    Future.delayed(const Duration(seconds: 1), () async {
      if (isDisconnected[0] || _isActivated || _isStopped) {
        return;
      }
      await _activateConnection(ticketID, ticketBytes);
      _loopActivateConnection(isDisconnected, ticketID, ticketBytes);
    });
  }

  void _loopRetrySendMessage() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (_isStopped) {
        return;
      }
      final itemQueue = _queueMessages.nextMessage();
      if (itemQueue == null) {
        _loopRetrySendMessage();
        return;
      }

      var content = Result(
        errorCode: ErrorCode.errorMessage,
        data: List<int>.empty(),
      );
      if (itemQueue.isGroup) {
        content = await _parser.buildGroupMessage(
          itemQueue.msgID.toInt(),
          itemQueue.msgTag.toInt(),
          itemQueue.recvName,
          itemQueue.content,
          itemQueue.isEncrypted,
          itemQueue.isCached,
          itemQueue.isFirst,
          itemQueue.isLast,
          itemQueue.isRequest,
        );
      } else {
        content = await _parser.buildMessage(
          itemQueue.msgID.toInt(),
          itemQueue.msgTag.toInt(),
          itemQueue.recvName,
          itemQueue.content,
          itemQueue.isEncrypted,
          itemQueue.isCached,
          itemQueue.isFirst,
          itemQueue.isLast,
          itemQueue.isRequest,
        );
      }
      if (content.errorCode == ErrorCode.success) {
        await _conn.sendMessage(content.data);
      }
      _loopRetrySendMessage();
    });
  }

  Future<Result<ServerTicket>> _prepare() async {
    final serverKey = await _proxy.exchangeKey();
    if (serverKey.errorCode != ErrorCode.success) {
      return Result(
        errorCode: serverKey.errorCode,
        data: ServerTicket.initDefault(),
      );
    }
    return _proxy.registerConnection(serverKey.data);
  }

  Future<int> _activateConnection(int ticketID, List<int> ticketBytes) async {
    final msg = await _parser.buildActivateMessage(ticketID, ticketBytes);
    if (msg.errorCode != ErrorCode.success) {
      return msg.errorCode;
    }
    return _conn.sendMessage(msg.data);
  }

  Future<int> _sendResponse(
    BigInt msgID,
    BigInt msgTag,
    String recvName,
    List<int> data,
    bool isEncrypted,
  ) async {
    final msg = await _parser.buildMessage(
      msgID.toInt(),
      msgTag.toInt(),
      recvName,
      data,
      isEncrypted,
      false,
      true,
      true,
      false,
    );
    if (msg.errorCode != ErrorCode.success) {
      return msg.errorCode;
    }
    return _conn.sendMessage(msg.data);
  }

  void _processMessage(
    List<int> content,
    Future<int> cb(String sender, List<int> data),
  ) async {
    final msg = await _parser.parseReceivedMessage(content);
    if (msg.errorCode != ErrorCode.success) {
      return;
    }
    final msgData = msg.data;

    final msgType = msgData.msgType;
    if (msgType == MessageType.activation) {
      final readyTicket = ReadyTicket.parseBytes(
        Uint8List.fromList(msgData.data).buffer,
      );
      if (readyTicket.errorCode != ErrorCode.success ||
          !readyTicket.data.isReady) {
        return;
      }
      _isActivated = true;
      if (_counter == null) {
        _counter = Counter(
          writeIndex: readyTicket.data.idxWrite,
          minReadIdx: readyTicket.data.idxRead,
          maskReadBits: readyTicket.data.maskRead.toInt(),
        );
      }
      return;
    }

    if (_isActivated == false) {
      return;
    }

    if (msgType != MessageType.done &&
        msgType != MessageType.single &&
        msgType != MessageType.singleCached) {
      if (msgType != MessageType.group && msgType != MessageType.groupCached) {
        return;
      }
    }

    if (msgData.msgID == BigInt.zero) {
      if (msgData.isRequest) {
        await cb(msgData.name, msgData.data);
      }
      return;
    }

    if (msgData.isRequest == false) {
      // response
      _queueMessages.clearMessage(msgData.msgID);
      return;
    }

    if (_counter?.markReadDone(msgData.msgTag) ?? false) {
      final errCode = await cb(msgData.name, msgData.data);
      if (errCode != ErrorCode.success) {
        _counter?.markReadUnused(msgData.msgTag);
        return;
      }
    }

    _sendResponse(
      msgData.msgID,
      msgData.msgTag,
      msgData.name,
      List.empty(),
      msgData.isEncrypted,
    );
  }
}
