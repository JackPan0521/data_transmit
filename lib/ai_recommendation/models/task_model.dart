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

  factory TaskModel.fromJson(Map<String, dynamic> json, DateTime selectedDate) {
    return TaskModel(
      eventName: json["事件"] ?? '',
      startTime: json["開始時間"] ?? '',
      endTime: json["結束時間"] ?? '',
      duration: (json["持續時間"] as num?)?.toInt() ?? 30,
      intelligenceField: json["多元智慧領域"] ?? '',
      year: json["年分"] ?? selectedDate.year,
      month: json["月份"] ?? selectedDate.month,
      day: json["日期"] ?? selectedDate.day,
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

  static Future<TaskModel?> selectTimeForTask({
    required BuildContext context,
    required Map<String, dynamic> taskData,
    required DateTime selectedDate,
  }) async {
    final duration = (taskData["持續時間"] as num?)?.toInt() ?? 30;

    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: "選擇 ${taskData["事件"]} 的開始時間",
    );
    
    if (startTime == null || !context.mounted) return null;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour + (duration ~/ 60),
        minute: startTime.minute + (duration % 60),
      ),
      helpText: "選擇 ${taskData["事件"]} 的結束時間",
    );
    
    if (endTime == null || !context.mounted) return null;

    // 驗證時間
    final startDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      endTime.hour,
      endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
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
      year: selectedDate.year,
      month: selectedDate.month,
      day: selectedDate.day,
    );
  }
}