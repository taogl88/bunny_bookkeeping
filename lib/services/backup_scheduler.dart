import 'package:cron/cron.dart';
import 'backup_service.dart';
import 'cos_storage_service.dart';
import 'backup_settings.dart';

class BackupScheduler {
  final BackupService _backupService;
  final BackupSettingsRepository _settingsRepo;
  Cron? _cron;

  BackupScheduler({
    required BackupService backupService,
    required BackupSettingsRepository settingsRepo,
  })  : _backupService = backupService,
        _settingsRepo = settingsRepo;

  Future<void> start() async {
    final settings = await _settingsRepo.load();
    if (!settings.enabled || !settings.isConfigured) return;

    _cron?.close();
    _cron = Cron();

    final cronExpr = _toCronExpression(settings.frequency);
    _cron!.schedule(Schedule.parse(cronExpr), () async {
      await runBackup(settings);
    });
  }

  Future<void> runBackup(BackupSettings settings) async {
    if (!settings.isConfigured) return;

    final cos = CosStorageService(
      secretId: settings.secretId!,
      secretKey: settings.secretKey!,
      bucket: settings.bucket!,
      region: settings.region!,
      appId: settings.appId!,
    );

    final data = await _backupService.exportToJson();
    final jsonStr = _backupService.toJsonString(data);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final key = 'backup/$timestamp.json';

    await cos.upload(key: key, data: jsonStr);
  }

  Future<void> stop() async {
    _cron?.close();
    _cron = null;
  }

  String _toCronExpression(String frequency) {
    switch (frequency) {
      case 'daily':
        return '0 3 * * *';
      case 'weekly':
        return '0 3 * * 0';
      case 'monthly':
        return '0 3 1 * *';
      default:
        return '0 3 * * *';
    }
  }
}

class BackupResult {
  final bool success;
  final String? fileName;
  final String? error;

  BackupResult({required this.success, this.fileName, this.error});
}