class Constant {
  static const lengthIV = 12;
  static const lengthAuthenTag = 16;
  static const lengthSign = 32;
}

class ErrorCode {
  static const success = 0;
  static const invalidBytes = 1;
  static const invalidConnectionName = 2;
  static const invalidToken = 3;
  static const invalidSignature = 4;
  static const invalidAddress = 5;
  static const errorMessage = 6;
  static const errorConnection = 7;
  static const errorQueueFull = 8;
}
