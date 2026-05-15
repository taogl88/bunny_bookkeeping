import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackupSettings {
  final bool enabled;
  final String frequency;
  final String? secretId;
  final String? secretKey;
  final String? bucket;
  final String? region;
  final String? appId;

  const BackupSettings({
    this.enabled = false,
    this.frequency = 'daily',
    this.secretId,
    this.secretKey,
    this.bucket,
    this.region,
    this.appId,
  });

  BackupSettings copyWith({
    bool? enabled,
    String? frequency,
    String? secretId,
    String? secretKey,
    String? bucket,
    String? region,
    String? appId,
  }) {
    return BackupSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      secretId: secretId ?? this.secretId,
      secretKey: secretKey ?? this.secretKey,
      bucket: bucket ?? this.bucket,
      region: region ?? this.region,
      appId: appId ?? this.appId,
    );
  }

  bool get isConfigured =>
      secretId != null &&
      secretKey != null &&
      bucket != null &&
      region != null &&
      appId != null;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'frequency': frequency,
        'secretId': secretId,
        'secretKey': secretKey,
        'bucket': bucket,
        'region': region,
        'appId': appId,
      };

  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      enabled: json['enabled'] as bool? ?? false,
      frequency: json['frequency'] as String? ?? 'daily',
      secretId: json['secretId'] as String?,
      secretKey: json['secretKey'] as String?,
      bucket: json['bucket'] as String?,
      region: json['region'] as String?,
      appId: json['appId'] as String?,
    );
  }
}

class BackupSettingsRepository {
  static const _key = 'backup_settings';

  Future<BackupSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return const BackupSettings();
    try {
      return BackupSettings.fromJson(
        Map<String, dynamic>.from(
          Map.castFrom(jsonDecode(json)),
        ),
      );
    } catch (_) {
      return const BackupSettings();
    }
  }

  Future<void> save(BackupSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}