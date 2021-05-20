// ServerKey is a group of server keys
class ServerKey {
  final BigInt _gKey;
  final BigInt _nKey;
  final BigInt _pubKey;

  ServerKey.initDefault()
      : _gKey = BigInt.zero,
        _nKey = BigInt.zero,
        _pubKey = BigInt.zero;

  ServerKey({
    required BigInt gKey,
    required BigInt nKey,
    required BigInt pubKey,
  })   : _gKey = gKey,
        _nKey = nKey,
        _pubKey = pubKey;

  BigInt get gKey => _gKey;
  BigInt get nKey => _nKey;
  BigInt get pubKey => _pubKey;
}

// ServerTicket is an activation ticket from the Hub server
class ServerTicket {
  final String _hubAddress;
  final int _ticketID;
  final List<int> _ticketBytes;
  final List<int> _serverSecretKey;

  ServerTicket.initDefault()
      : _hubAddress = '',
        _ticketID = 0,
        _ticketBytes = List.empty(),
        _serverSecretKey = List.empty();

  ServerTicket({
    required String hubAddress,
    required int ticketID,
    required List<int> ticketBytes,
    required List<int> serverSecretKey,
  })   : _hubAddress = hubAddress,
        _ticketID = ticketID,
        _ticketBytes = ticketBytes,
        _serverSecretKey = serverSecretKey;

  String get hubAddress => _hubAddress;
  BigInt get ticketID => BigInt.from(_ticketID).toUnsigned(16);
  List<int> get ticketBytes => _ticketBytes;
  List<int> get serverSecretKey => _serverSecretKey;
}

// Response is format message of HTTP response from the Proxy server
class Response {
  final int _returnCode;
  final int _timestamp;
  final dynamic _data;

  Response.fromJson(Map<String, dynamic> json)
      : _returnCode = json['returncode'] ?? '0',
        _timestamp = BigInt.from(
          json['timestamp'] ?? '0',
        ).toUnsigned(64).toInt(),
        _data = json['data'];

  int get returnCode => _returnCode;
  BigInt get timestamp => BigInt.from(_timestamp).toUnsigned(64);
  dynamic get data => _data;
}

// RespExchangeKey is response of exchange-key API from the Proxy server
class RespExchangeKey {
  final String _gKey;
  final String _nKey;
  final String _pubKey;
  final String _sign; // using RSA to validate

  RespExchangeKey.fromJson(Map<String, dynamic> json)
      : _gKey = json['g_key'] ?? '0',
        _nKey = json['n_key'] ?? '0',
        _pubKey = json['pub_key'] ?? '0',
        _sign = json['sign'] ?? '';

  String get gKey => _gKey;
  String get nKey => _nKey;
  String get pubKey => _pubKey;
  String get sign => _sign;
}

// RespRegisterConnection is response of register-connection API from the Proxy server
class RespRegisterConnection {
  final String _hubAddress;
  final int _ticketID;
  final String _ticketToken;
  final String _pubKey;
  final String _iv;
  final String _authenTag;

  RespRegisterConnection.fromJson(Map<String, dynamic> json)
      : _hubAddress = json['hub_address'] ?? '',
        _ticketID = json['ticket_id'] ?? 0,
        _ticketToken = json['ticket_token'] ?? '',
        _pubKey = json['pub_key'] ?? '0',
        _iv = json['iv'] ?? '',
        _authenTag = json['auth_tag'] ?? '';

  String get hubAddress => _hubAddress;
  BigInt get ticketID => BigInt.from(_ticketID).toUnsigned(16);
  String get ticketToken => _ticketToken;
  String get pubKey => _pubKey;
  String get iv => _iv;
  String get authenTag => _authenTag;
}
