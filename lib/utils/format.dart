/// 格式化日期时间为 'yyyy-MM-dd HH:mm'。
String formatDateTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

/// 体重保留 1 位小数显示（单位 kg）。
String formatWeightKg(double kg) => '${kg.toStringAsFixed(1)} kg';
