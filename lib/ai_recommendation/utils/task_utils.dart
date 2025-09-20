import 'package:flutter/material.dart';

class TaskUtils {
  /// 根據事件名稱返回對應的圖標
  static IconData getEventIcon(String? eventName) {
    if (eventName == null) return Icons.event;
    
    final name = eventName.toLowerCase();
    if (name.contains('運動') || name.contains('健身')) {
      return Icons.fitness_center;
    }
    if (name.contains('工作') || name.contains('會議')) {
      return Icons.work;
    }
    if (name.contains('餐') || name.contains('吃')) {
      return Icons.restaurant;
    }
    if (name.contains('學習') || name.contains('讀書')) {
      return Icons.school;
    }
    if (name.contains('休息') || name.contains('放鬆')) {
      return Icons.self_improvement;
    }
    if (name.contains('娛樂') || name.contains('遊戲')) {
      return Icons.sports_esports;
    }
    if (name.contains('購物')) {
      return Icons.shopping_cart;
    }
    if (name.contains('交通') || name.contains('通勤')) {
      return Icons.directions_car;
    }
    if (name.contains('醫療') || name.contains('看醫生')) {
      return Icons.local_hospital;
    }
    if (name.contains('社交') || name.contains('聚會')) {
      return Icons.people;
    }
    return Icons.event;
  }

  /// 格式化時間字串
  static String formatTimeString(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// 驗證時間範圍
  static bool isValidTimeRange(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes > startMinutes;
  }

  /// 計算時間差（分鐘）
  static int calculateDurationInMinutes(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    var endMinutes = endTime.hour * 60 + endTime.minute;
    
    // 如果結束時間小於開始時間，表示跨夜
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }
    
    return endMinutes - startMinutes;
  }
}