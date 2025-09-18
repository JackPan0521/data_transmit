class ScheduleUtils {
  /// 格式化日期為 yyyy-MM-dd 格式
  static String formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String formatDateKey(DateTime date) {
    // 使用與 formatDate 相同的格式，因為現在我們使用 yyyy-MM-dd 作為文檔 ID
    return formatDate(date);
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}