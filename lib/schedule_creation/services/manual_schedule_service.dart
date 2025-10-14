import 'package:flutter/material.dart';
import '../../home_screen/services/calendar_firebase_service.dart';
import '../../home_screen/models/schedule_item.dart';

class ManualScheduleService {
  // 載入行程列表
  static Future<List<ScheduleItem>> loadSchedules(DateTime selectedDay) async {
    try {
      return await CalendarFirebaseService.loadSchedules(selectedDay);
    } catch (e) {
      throw Exception('載入行程失敗：$e');
    }
  }

  // 新增行程
  static Future<void> addSchedule({
    required DateTime selectedDay,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await CalendarFirebaseService.addSchedule(
        selectedDay: selectedDay,
        name: description,
        desc: description,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      throw Exception('新增行程失敗：$e');
    }
  }

  // 驗證輸入
  static String? validateInput({
    required String description,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    if (description.trim().isEmpty) {
      return '請填入行程內容';
    }

    if (startTime == null || endTime == null) {
      return '請選擇開始和結束時間';
    }

    return null; // 驗證通過
  }

  // 驗證時間邏輯
  static String? validateTimeLogic({
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) {
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      return '結束時間必須晚於開始時間';
    }

    return null; // 驗證通過
  }

  // 建立時間 DateTime
  static DateTime createDateTime({
    required DateTime selectedDay,
    required TimeOfDay time,
  }) {
    return DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      time.hour,
      time.minute,
    );
  }
}