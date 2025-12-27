//時間工具類
//提供時間計算功能，包括計算持續時間、智能調整結束時間、驗證時間範圍等功能
import 'package:flutter/material.dart';

class TimeUtils {
  // 計算持續時間
  static String calculateDuration(TimeOfDay start, TimeOfDay end) {
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;
    
    // 處理跨日情況
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }
    
    final durationMinutes = endMinutes - startMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      // ignore: unnecessary_brace_in_string_interps
      return '${hours}小時${minutes}分鐘';
    } else if (hours > 0) {
      return '$hours小時';
    } else {
      return '$minutes分鐘';
    }
  }

  // 智能調整結束時間
  static TimeOfDay adjustEndTime(TimeOfDay startTime) {
    return TimeOfDay(
      hour: (startTime.hour + 1) % 24,
      minute: startTime.minute,
    );
  }

  // 檢查結束時間是否需要調整
  static bool shouldAdjustEndTime(TimeOfDay startTime, TimeOfDay? endTime) {
    if (endTime == null) return true;
    
    return endTime.hour < startTime.hour ||
           (endTime.hour == startTime.hour && endTime.minute <= startTime.minute);
  }
}