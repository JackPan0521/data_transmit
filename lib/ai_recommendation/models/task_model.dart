import 'package:flutter/material.dart';

class TaskModel {
  final String eventName;
  final String startTime;
  final String endTime;
  final int duration;
  final String intelligenceField;
  final int year;
  final int month;
  final int day;

  TaskModel({
    required this.eventName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.intelligenceField,
    required this.year,
    required this.month,
    required this.day,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json, DateTime fallbackDate) {
    return TaskModel(
      eventName: json["事件"] ?? '',
      startTime: json["開始時間"] ?? '',
      endTime: json["結束時間"] ?? '',
      duration: (json["持續時間"] as num?)?.toInt() ?? 30,
      intelligenceField: json["多元智慧領域"] ?? '',
      year: json["年分"] ?? fallbackDate.year,
      month: json["月份"] ?? fallbackDate.month,
      day: json["日期"] ?? fallbackDate.day,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "事件": eventName,
      "開始時間": startTime,
      "結束時間": endTime,
      "持續時間": duration,
      "多元智慧領域": intelligenceField,
      "年分": year,
      "月份": month,
      "日期": day,
    };
  }

  Map<String, dynamic> toScheduleFormat() {
    return {
      'name': eventName,
      'desc': intelligenceField,
      'startTime': startTime,
      'endTime': endTime,
      'date': DateTime(year, month, day),
    };
  }

  /// 只選擇時間，使用 AI 提供的日期
  static Future<TaskModel?> selectTimeForTask({
    required BuildContext context,
    required Map<String, dynamic> taskData,
    required DateTime defaultDate,
  }) async {
    // 使用 AI JSON 中的日期資訊，如果沒有則使用 defaultDate
    final targetDate = DateTime(
      taskData["年分"] ?? defaultDate.year,
      taskData["月份"] ?? defaultDate.month,
      taskData["日期"] ?? defaultDate.day,
    );

    // 顯示確認對話框，讓使用者知道將安排到哪一天
    final bool? confirmDate = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final dateStr = "${targetDate.year}/${targetDate.month}/${targetDate.day}";
        final weekday = _getWeekdayName(targetDate.weekday);
        
        return AlertDialog(
          title: const Text("確認安排日期"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("行程：${taskData["事件"]}"),
              const SizedBox(height: 8),
              Text("將安排到：$dateStr ($weekday)"),
              const SizedBox(height: 8),
              Text(
                "是否繼續設定時間？",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("取消"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("確定"),
            ),
          ],
        );
      },
    );

    if (confirmDate != true || !context.mounted) return null;

    final duration = (taskData["持續時間"] as num?)?.toInt() ?? 30;

    // 解析 AI 提供的開始時間，如果沒有則使用預設值
    TimeOfDay initialStartTime = const TimeOfDay(hour: 9, minute: 0);
    if (taskData["開始時間"] != null && taskData["開始時間"].toString().isNotEmpty) {
      try {
        final timeParts = taskData["開始時間"].toString().split(':');
        if (timeParts.length == 2) {
          initialStartTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        // 如果解析失敗，使用預設時間
      }
    }

    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: initialStartTime,
      helpText: "選擇 ${taskData["事件"]} 的開始時間",
    );
    
    if (startTime == null || !context.mounted) return null;

    // 計算建議的結束時間（修正版本）
    int totalMinutes = startTime.hour * 60 + startTime.minute + duration;
    TimeOfDay suggestedEndTime = TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24, // 防止超過 24 小時，使用模運算
      minute: totalMinutes % 60,
    );

    // 如果 AI 有提供結束時間，優先使用
    if (taskData["結束時間"] != null && taskData["結束時間"].toString().isNotEmpty) {
      try {
        final timeParts = taskData["結束時間"].toString().split(':');
        if (timeParts.length == 2) {
          suggestedEndTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        // 如果解析失敗，使用計算的時間
      }
    }

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: suggestedEndTime,
      helpText: "選擇 ${taskData["事件"]} 的結束時間",
    );
    
    if (endTime == null || !context.mounted) return null;

    // 驗證時間（考慮跨日情況）
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // 如果結束時間小於開始時間，可能是跨日，但在同一天內不允許
    if (endMinutes <= startMinutes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("結束時間必須晚於開始時間")),
        );
      }
      return null;
    }

    final startTimeStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    final endTimeStr = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
    
    return TaskModel(
      eventName: taskData["事件"] ?? '',
      startTime: startTimeStr,
      endTime: endTimeStr,
      duration: duration,
      intelligenceField: taskData["多元智慧領域"] ?? '',
      year: targetDate.year,
      month: targetDate.month,
      day: targetDate.day,
    );
  }

  /// 格式化日期顯示
  String get formattedDate {
    return "$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}";
  }

  /// 獲取星期幾
  String get weekdayName {
    final date = DateTime(year, month, day);
    return _getWeekdayName(date.weekday);
  }

  static String _getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekdays[weekday - 1]}';
  }

  /// 輔助方法：安全計算結束時間
  static TimeOfDay calculateEndTime(TimeOfDay startTime, int durationMinutes) {
    int totalMinutes = startTime.hour * 60 + startTime.minute + durationMinutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }
}