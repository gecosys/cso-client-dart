import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

abstract class IConfig {
  String getProjectID();
  String getProjectToken();
  String getConnectionName();
  String getCSOPublicKey();
  String getCSOAddress();
}

class Config implements IConfig {
  final String _projectID;
  final String _projectToken;
  final String _connName;
  final String _csoPublicKey;
  final String _csoAddress;

  Config({
    required String projectID,
    required String projectToken,
    required String connName,
    required String csoPublicKey,
    required String csoAddress,
  })   : _projectID = projectID,
        _projectToken = projectToken,
        _connName = connName,
        _csoPublicKey = csoPublicKey,
        _csoAddress = csoAddress;

  static Future<Config> fromFile(String filePath) async {
    final jsonData = await rootBundle
        .loadString(filePath)
        .then((fileContents) => json.decode(fileContents));
    return Future.value(Config(
      projectID: jsonData["pid"],
      projectToken: jsonData["ptoken"],
      connName: jsonData["cname"],
      csoPublicKey: jsonData["csopubkey"],
      csoAddress: jsonData["csoaddr"],
    ));
  }

  String getProjectID() {
    return this._projectID;
  }

  String getProjectToken() {
    return this._projectToken;
  }

  String getConnectionName() {
    return this._connName;
  }

  String getCSOPublicKey() {
    return this._csoPublicKey;
  }

  String getCSOAddress() {
    return this._csoAddress;
  }
}
