abstract class IConnection {
  Future<void> close();
  Future<int> listen(
    String address, {
    required void onMessage(List<int> msg),
    required void onDisconnected(),
  });
  Future<int> sendMessage(List<int> data);
}
