import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

abstract class IConfig {
  String get projectID;
  String get projectToken;
  String get connName;
  String get csoPublicKey;
  String get csoAddress;
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
    return Config(
      projectID: jsonData["pid"],
      projectToken: jsonData["ptoken"],
      connName: jsonData["cname"],
      csoPublicKey: jsonData["csopubkey"],
      csoAddress: jsonData["csoaddr"],
    );
  }

  String get projectID => _projectID;
  String get projectToken => _projectToken;
  String get connName => _connName;
  String get csoPublicKey => _csoPublicKey;
  String get csoAddress => _csoAddress;
}
