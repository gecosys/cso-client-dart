import 'dart:convert';

import 'package:cso_client_flutter/message/define.dart';
import 'package:cso_client_flutter/message/ticket.dart';
import 'package:cso_client_flutter/utils/aes.dart';
import 'package:cso_client_flutter/utils/dh.dart';
import 'package:cso_client_flutter/utils/rsa.dart';
import 'package:http/http.dart' as http;
import 'package:cso_client_flutter/config/config.dart';
import 'package:cso_client_flutter/csoproxy/proxy_message.dart';
import 'package:cso_client_flutter/csoproxy/proxy_interface.dart';
import 'package:cso_client_flutter/message/result.dart';

class Proxy implements IProxy {
  IConfig _conf;

  Proxy(IConfig conf) : _conf = conf;

  Future<Result<ServerKey>> exchangeKey() async {
    final url = '${this._conf.getCSOAddress()}/exchange-key';

    final httpResp = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(<String, String>{
        'project_id': this._conf.getProjectID(),
        'unique_name': this._conf.getConnectionName(),
      }),
    );

    // Parse response
    final resp = Response.fromJson(json.decode(httpResp.body));
    if (resp.returnCode != 1 || resp.data == null) {
      return Future.value(
        Result(
          errorCode: ErrorCode.errorMessage,
          data: ServerKey.initDefault(),
        ),
      );
    }
    final respExchangeKey = RespExchangeKey.fromJson(resp.data);

    // Parse signature base64
    final sign = base64.decode(respExchangeKey.sign);

    // Verify DH keys with the signature
    final gKeyBytes = respExchangeKey.gKey.codeUnits;
    final nKeyBytes = respExchangeKey.nKey.codeUnits;
    final serverPubKeyBytes = respExchangeKey.pubKey.codeUnits;
    final lenGKey = gKeyBytes.length;
    final lenGNKey = lenGKey + nKeyBytes.length;
    final lenBuffer = lenGNKey + serverPubKeyBytes.length;
    final buffer = List<int>.filled(lenBuffer, 0, growable: false);
    buffer.setAll(0, gKeyBytes);
    buffer.setAll(lenGKey, nKeyBytes);
    buffer.setAll(lenGNKey, serverPubKeyBytes);
    final isValid = await RSA.verifySignature(
      this._conf.getCSOPublicKey(),
      sign,
      buffer,
    );
    if (isValid == false) {
      return Future.value(
        Result(
          errorCode: ErrorCode.invalidSignature,
          data: ServerKey.initDefault(),
        ),
      );
    }

    // Parse DH keys to BigInt
    return Future.value(
      Result(
        errorCode: ErrorCode.success,
        data: ServerKey(
          gKey: BigInt.parse(respExchangeKey.gKey),
          nKey: BigInt.parse(respExchangeKey.nKey),
          pubKey: BigInt.parse(respExchangeKey.pubKey),
        ),
      ),
    );
  }

  Future<Result<ServerTicket>> registerConnection(ServerKey serverKey) async {
    final clientPrivKey = DH.generatePrivateKey();

    // Calculate secret key (AES-GCM)
    final clientPubKey = DH.calcPublicKey(
      serverKey.gKey,
      serverKey.nKey,
      clientPrivKey,
    );
    final clientSecretKey = await DH.calcSecretKey(
      serverKey.nKey,
      clientPrivKey,
      serverKey.pubKey,
    );

    // Encrypt project's token by AES-GCM
    final projectID = this._conf.getProjectID();
    final connName = this._conf.getConnectionName();
    final decodedToken = base64.decode(this._conf.getProjectToken());
    final strClientPubKey = clientPubKey.toString();
    final lenProjectID = projectID.length;
    final lenProjectIDConnName = lenProjectID + connName.length;
    final lenAAD = lenProjectIDConnName + strClientPubKey.length;
    final clientAad = List<int>.filled(lenAAD, 0, growable: false);
    clientAad.setAll(0, projectID.codeUnits);
    clientAad.setAll(lenProjectID, connName.codeUnits);
    clientAad.setAll(lenProjectIDConnName, strClientPubKey.codeUnits);
    final cipherProjectToken = await AES.encrypt(
      clientSecretKey,
      decodedToken,
      clientAad,
    );

    // Invoke API
    final url = '${this._conf.getCSOAddress()}/register-connection';
    final httpResp = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(<String, String>{
        'project_id': projectID,
        'project_token': base64.encode(cipherProjectToken.cipherText),
        'unique_name': connName,
        'public_key': strClientPubKey,
        'iv': base64.encode(cipherProjectToken.nonce),
        'authen_tag': base64.encode(cipherProjectToken.mac.bytes)
      }),
    );

    // Parse response
    final resp = Response.fromJson(json.decode(httpResp.body));
    if (resp.returnCode != 1 || resp.data == null) {
      return Future.value(
        Result(
          errorCode: ErrorCode.errorMessage,
          data: ServerTicket.initDefault(),
        ),
      );
    }
    final respRegisterConnection = RespRegisterConnection.fromJson(resp.data);

    // Decrypt ticket's token
    final lenAadAddress = 2 + respRegisterConnection.hubAddress.length;
    final serverAad = List<int>.filled(
      lenAadAddress + respRegisterConnection.pubKey.length,
      0,
      growable: false,
    );
    final valTicketID = BigInt.from(
      respRegisterConnection.ticketID,
    ).toUnsigned(16);
    serverAad[0] = valTicketID.toUnsigned(8).toInt();
    serverAad[1] = (valTicketID >> 8).toUnsigned(8).toInt();
    serverAad.setAll(2, respRegisterConnection.hubAddress.codeUnits);
    serverAad.setAll(lenAadAddress, respRegisterConnection.pubKey.codeUnits);

    final serverPubKey = BigInt.parse(respRegisterConnection.pubKey);
    final serverSecretKey = await DH.calcSecretKey(
      serverKey.nKey,
      clientPrivKey,
      serverPubKey,
    );
    final serverIV = base64.decode(respRegisterConnection.iv);
    final serverAuthenTag = base64.decode(respRegisterConnection.authenTag);
    final serverTicketToken = base64.decode(respRegisterConnection.ticketToken);
    final ticketToken = await AES.decrypt(
      serverSecretKey,
      serverIV,
      serverAuthenTag,
      serverTicketToken,
      serverAad,
    );

    // Build ticket bytes
    final ticketBytes = Ticket.buildBytes(valTicketID.toInt(), ticketToken);
    if (ticketBytes.errorCode != ErrorCode.success) {
      return Future.value(
        Result(
          errorCode: ticketBytes.errorCode,
          data: ServerTicket.initDefault(),
        ),
      );
    }

    return Future.value(
      Result(
        errorCode: ErrorCode.success,
        data: ServerTicket(
          hubAddress: respRegisterConnection.hubAddress,
          ticketID: valTicketID.toInt(),
          ticketBytes: ticketBytes.data,
          serverSecretKey: serverSecretKey,
        ),
      ),
    );
  }
}