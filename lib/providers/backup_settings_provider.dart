import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_settings.dart';
import '../services/backup_service.dart';
import '../services/backup_scheduler.dart';

final backupSettingsProvider =
    AsyncNotifierProvider<BackupSettingsNotifier, BackupSettings>(() {
  return BackupSettingsNotifier();
});

class BackupSettingsNotifier extends AsyncNotifier<BackupSettings> {
  final _repo = BackupSettingsRepository();

  @override
  Future<BackupSettings> build() async {
    return await _repo.load();
  }

  Future<void> updateSettings(BackupSettings settings) async {
    state = AsyncData(settings);
    await _repo.save(settings);
  }

  Future<void> toggleEnabled(bool enabled) async {
    final current = state.value ?? const BackupSettings();
    final next = current.copyWith(enabled: enabled);
    await updateSettings(next);
  }

  Future<void> updateFrequency(String frequency) async {
    final current = state.value ?? const BackupSettings();
    final next = current.copyWith(frequency: frequency);
    await updateSettings(next);
  }

  Future<void> updateCosConfig({
    String? secretId,
    String? secretKey,
    String? bucket,
    String? region,
    String? appId,
  }) async {
    final current = state.value ?? const BackupSettings();
    final next = current.copyWith(
      secretId: secretId,
      secretKey: secretKey,
      bucket: bucket,
      region: region,
      appId: appId,
    );
    await updateSettings(next);
  }
}

final manualBackupProvider = Provider<ManualBackupService>((ref) {
  return ManualBackupService(
    backupService: BackupService(),
    settingsRepo: BackupSettingsRepository(),
  );
});

class ManualBackupService {
  final BackupService _backupService;
  final BackupSettingsRepository _settingsRepo;

  ManualBackupService({
    required BackupService backupService,
    required BackupSettingsRepository settingsRepo,
  })  : _backupService = backupService,
        _settingsRepo = settingsRepo;

  Future<ManualBackupResult> run() async {
    final settings = await _settingsRepo.load();
    if (!settings.isConfigured) {
      return ManualBackupResult(
        success: false,
        error: '请先配置云存储参数',
      );
    }

    try {
      final data = await _backupService.exportToJson();
      final jsonStr = _backupService.toJsonString(data);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'backup/$timestamp.json';

      return ManualBackupResult(
        success: true,
        fileName: fileName,
        sizeBytes: jsonStr.length,
        recordCount: data.bills.length + data.categories.length,
      );
    } catch (e) {
      return ManualBackupResult(success: false, error: e.toString());
    }
  }
}

class ManualBackupResult {
  final bool success;
  final String? fileName;
  final int? sizeBytes;
  final int? recordCount;
  final String? error;

  ManualBackupResult({
    required this.success,
    this.fileName,
    this.sizeBytes,
    this.recordCount,
    this.error,
  });
}