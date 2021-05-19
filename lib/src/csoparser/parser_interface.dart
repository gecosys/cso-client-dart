import '../message/cipher.dart';
import '../message/result.dart';

abstract class IParser {
  set secretKey(List<int> value);

  Future<Result<Cipher>> parseReceivedMessage(List<int> content);
  Future<Result<List<int>>> buildActivateMessage(
    int ticketID,
    List<int> ticketBytes,
  );
  Future<Result<List<int>>> buildMessage(
    int msgID,
    int msgTag,
    String recvName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
    bool isFirst,
    bool isLast,
    bool isRequest,
  );
  Future<Result<List<int>>> buildGroupMessage(
    int msgID,
    int msgTag,
    String groupName,
    List<int> content,
    bool isEncrypted,
    bool isCached,
    bool isFirst,
    bool isLast,
    bool isRequest,
  );
}
