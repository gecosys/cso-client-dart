import 'dart:convert';

import 'package:http/http.dart' as http;

import 'proxy_message.dart';
import 'proxy_interface.dart';

import '../message/define.dart';
import '../message/ticket.dart';
import '../utils/aes.dart';
import '../utils/dh.dart';
import '../utils/rsa.dart';
import '../config/config.dart';
import '../message/result.dart';

class Proxy implements IProxy {
  IConfig _conf;

  Proxy(IConfig conf) : _conf = conf;

  Future<Result<ServerKey>> exchangeKey() async {
    final url = '${_conf.csoAddress}/exchange-key';

    final httpResp = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(<String, String>{
        'project_id': _conf.projectID,
        'unique_name': _conf.connName,
      }),
    );

    // Parse response
    final resp = Response.fromJson(json.decode(httpResp.body));
    if (resp.returnCode != 1 || resp.data == null) {
      return Result(
        errorCode: ErrorCode.errorMessage,
        data: ServerKey.initDefault(),
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
      _conf.csoPublicKey,
      sign,
      buffer,
    );
    if (isValid == false) {
      return Result(
        errorCode: ErrorCode.invalidSignature,
        data: ServerKey.initDefault(),
      );
    }

    // Parse DH keys to BigInt
    return Result(
      errorCode: ErrorCode.success,
      data: ServerKey(
        gKey: BigInt.parse(respExchangeKey.gKey),
        nKey: BigInt.parse(respExchangeKey.nKey),
        pubKey: BigInt.parse(respExchangeKey.pubKey),
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
    final projectID = _conf.projectID;
    final connName = _conf.connName;
    final decodedToken = base64.decode(_conf.projectToken);
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
    final url = '${_conf.csoAddress}/register-connection';
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
      return Result(
        errorCode: ErrorCode.errorMessage,
        data: ServerTicket.initDefault(),
      );
    }
    final respRegisterConnection = RespRegisterConnection.fromJson(
      resp.data,
    );

    // Decrypt ticket's token
    final lenAadAddress = 2 + respRegisterConnection.hubAddress.length;
    final serverAad = List<int>.filled(
      lenAadAddress + respRegisterConnection.pubKey.length,
      0,
      growable: false,
    );
    final valTicketID = respRegisterConnection.ticketID;
    serverAad[0] = valTicketID.toUnsigned(8).toInt();
    serverAad[1] = (valTicketID >> 8).toUnsigned(8).toInt();
    serverAad.setAll(2, respRegisterConnection.hubAddress.codeUnits);
    serverAad.setAll(
      lenAadAddress,
      respRegisterConnection.pubKey.codeUnits,
    );

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
      return Result(
        errorCode: ticketBytes.errorCode,
        data: ServerTicket.initDefault(),
      );
    }

    return Result(
      errorCode: ErrorCode.success,
      data: ServerTicket(
        hubAddress: respRegisterConnection.hubAddress,
        ticketID: valTicketID.toInt(),
        ticketBytes: ticketBytes.data,
        serverSecretKey: serverSecretKey,
      ),
    );
  }
}
