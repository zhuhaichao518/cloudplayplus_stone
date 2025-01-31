import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  /// 使用 Dart 自带的 `hashCode` 计算字符串哈希
  static int simpleHash(String input) {
    return input.hashCode;
  }

  /// 计算 SHA-256 哈希值，返回 64 位十六进制字符串
  static String hash(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
