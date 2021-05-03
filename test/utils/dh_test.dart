import 'package:cso_client_flutter/src/utils/dh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Calculate public key", () {
    final gKey = BigInt.parse(
      "13085740283905626820190858327830229325074398144037919390264787217970762155500475913384889705573207415264781772897028808189075971005535422580031180982983773",
    );
    final nKey = BigInt.parse(
      "12051447137828575061975455577585417152919244255306611070457381591481603618733496793766006006129998460225987670553077283464692974274072247248844186548041683",
    );
    final privKey = BigInt.parse(
      "1161222551009399897601626584343093107569828986835543298",
    );
    final pubKey = DH.calcPublicKey(gKey, nKey, privKey);
    expect(
      pubKey.toString(),
      "4854338121164001605381232913295330491739878694842669757464165622422342271997980347016219733563906638039053348308098987281598460292274228637952513069208495",
    );
  });
  test("Calculate secret key", () async {
    final nKey = BigInt.parse(
      "13381033606344000179436578353879229574133913718280139744619632645122285149768020367182494085299697457915895395268725604069670842523359610022829523960433474",
    );
    final clientPrivKey = BigInt.parse(
      "28895646741612077425303648205359313057499345712545781",
    );
    final serverPubKey = BigInt.parse(
      "9248905619971112930131286952991890135082366766988418986073542071216710337294299592371044282843911221395317715668521234249198597915439852784867535314172156",
    );
    final expectedSecretKey = [
      140,
      34,
      32,
      16,
      190,
      30,
      86,
      112,
      191,
      254,
      35,
      254,
      55,
      187,
      216,
      183,
      228,
      35,
      121,
      11,
      185,
      179,
      187,
      112,
      170,
      190,
      126,
      218,
      85,
      61,
      28,
      93
    ];
    final secretKey = await DH.calcSecretKey(
      nKey,
      clientPrivKey,
      serverPubKey,
    );
    expect(secretKey, expectedSecretKey);
  });
}
