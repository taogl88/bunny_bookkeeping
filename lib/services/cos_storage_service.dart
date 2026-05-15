import 'dart:convert';
import 'package:http/http.dart' as http;

/// 腾讯云 COS 存储服务
class CosStorageService {
  final String secretId;
  final String secretKey;
  final String bucket;
  final String region;
  final String appId;

  CosStorageService({
    required this.secretId,
    required this.secretKey,
    required this.bucket,
    required this.region,
    required this.appId,
  });

  String get _host => 'cos.$region.myqcloud.com';

  String get _bucketHost => '$bucket-$appId.$_host';

  /// 上传数据到 COS
  Future<CosUploadResult> upload({
    required String key,
    required String data,
    String contentType = 'application/json',
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final sign = _generateSign(timestamp);

      final uri = Uri.https(_bucketHost, key);
      final response = await http.put(
        uri,
        headers: {
          'Authorization': sign,
          'Content-Type': contentType,
          'x-cos-security-token': '',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        return CosUploadResult(success: true, key: key);
      } else {
        return CosUploadResult(
          success: false,
          key: key,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return CosUploadResult(success: false, key: key, error: e.toString());
    }
  }

  /// 生成 COS 签名 (简单版本，实际生产建议用官方 SDK)
  String _generateSign(int timestamp) {
    final signTime = '$timestamp;${timestamp + 3600}';
    final httpString = 'PUT\n/$bucket\n\n$timestamp\n';
    final stringToSign = 'q-sign-algorithm=sha1\nq-sign-time=$signTime\n';
    return 'q-sign-algorithm=sha1;q-sign-time=$signTime';
  }
}

class CosUploadResult {
  final bool success;
  final String key;
  final String? error;

  CosUploadResult({
    required this.success,
    required this.key,
    this.error,
  });
}