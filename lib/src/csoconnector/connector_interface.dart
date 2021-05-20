abstract class IConnector {
  Future<void> close();
  void listen(Future<int> cb(String sender, List<int> data));
  Future<int> sendMessage(
    String recvName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
  );
  Future<int> sendGroupMessage(
    String groupName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
  );
  Future<int> sendMessageAndRetry(
    String recvName,
    List<int> content,
    bool isEncrypted,
    int numberRetry,
  );
  Future<int> sendGroupMessageAndRetry(
    String groupName,
    List<int> content,
    bool isEncrypted,
    int numberRetry,
  );
}
