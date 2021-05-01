// ServerKey is a group of server keys
class ServerKey {
  final BigInt gKey;
  final BigInt nKey;
  final BigInt pubKey;

  ServerKey.initDefault()
      : gKey = BigInt.zero,
        nKey = BigInt.zero,
        pubKey = BigInt.zero;

  ServerKey({
    required this.gKey,
    required this.nKey,
    required this.pubKey,
  });
}

// ServerTicket is an activation ticket from the Hub server
class ServerTicket {
  final String hubAddress;
  final int ticketID;
  final List<int> ticketBytes;
  final List<int> serverSecretKey;

  ServerTicket.initDefault()
      : hubAddress = '',
        ticketID = 0,
        ticketBytes = List.empty(),
        serverSecretKey = List.empty();

  ServerTicket(
      {required this.hubAddress,
      required this.ticketID,
      required this.ticketBytes,
      required this.serverSecretKey});
}

// Response is format message of HTTP response from the Proxy server
class Response {
  final int returnCode;
  final int timestamp;
  final dynamic data;

  Response.fromJson(Map<String, dynamic> json)
      : returnCode = json['returncode'] ?? '0',
        timestamp = BigInt.from(
          json['timestamp'] ?? '0',
        ).toUnsigned(64).toInt(),
        data = json['data'];
}

// RespExchangeKey is response of exchange-key API from the Proxy server
class RespExchangeKey {
  final String gKey;
  final String nKey;
  final String pubKey;
  final String sign; // using RSA to validate

  RespExchangeKey.fromJson(Map<String, dynamic> json)
      : gKey = json['g_key'] ?? '0',
        nKey = json['n_key'] ?? '0',
        pubKey = json['pub_key'] ?? '0',
        sign = json['sign'] ?? '';
}

// RespRegisterConnection is response of register-connection API from the Proxy server
class RespRegisterConnection {
  final String hubAddress;
  final int ticketID;
  final String ticketToken;
  final String pubKey;
  final String iv;
  final String authenTag;

  RespRegisterConnection.fromJson(Map<String, dynamic> json)
      : hubAddress = json['hub_address'] ?? '',
        ticketID = json['ticket_id'] ?? 0,
        ticketToken = json['ticket_token'] ?? '',
        pubKey = json['pub_key'] ?? '0',
        iv = json['iv'] ?? '',
        authenTag = json['auth_tag'] ?? '';
}
