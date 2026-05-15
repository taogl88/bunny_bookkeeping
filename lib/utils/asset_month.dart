String currentAssetYearMonth([DateTime? now]) {
  final value = now ?? DateTime.now();
  return '${value.year}-${value.month.toString().padLeft(2, '0')}';
}

String? normalizeAssetYearMonth(String input) {
  final match = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(input.trim());
  if (match == null) {
    return null;
  }

  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  if (year == null || month == null || month < 1 || month > 12) {
    return null;
  }

  return '$year-${month.toString().padLeft(2, '0')}';
}

String assetMonthShortLabel(String yearMonth) {
  final normalized = normalizeAssetYearMonth(yearMonth);
  if (normalized == null) {
    return '--';
  }
  return normalized.substring(5);
}
