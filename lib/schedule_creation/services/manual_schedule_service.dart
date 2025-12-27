//手動行程服務
//主要功能：賽生日曆 Firebase 服務，提供手動新增、削除、編輯行程的操作
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

  // 檢查是否與已存在的行程重疊
  // 回傳 null 表示沒有重疊，否則回傳錯誤訊息（會說明是開始或結束時間重疊）
  static String? checkOverlapWithExisting({
    required List<ScheduleItem> existingSchedules,
    required DateTime candidateStart,
    required DateTime candidateEnd,
  }) {
    // 收集重疊的描述
    final List<String> startConflicts = [];
    final List<String> endConflicts = [];
    final List<String> genericConflicts = [];

    for (final s in existingSchedules) {
      final existingStart = s.startDateTime;
      final existingEnd = s.endDateTime;

      if (existingStart == null || existingEnd == null) continue;

      // candidate start 在 existing 區間內
      if ((candidateStart.isAtSameMomentAs(existingStart) || candidateStart.isAfter(existingStart)) && candidateStart.isBefore(existingEnd)) {
        startConflicts.add('${s.desc} (${s.time})');
      }

      // candidate end 在 existing 區間內（包含等於 existingEnd）
      if (candidateEnd.isAfter(existingStart) && (candidateEnd.isBefore(existingEnd) || candidateEnd.isAtSameMomentAs(existingEnd))) {
        endConflicts.add('${s.desc} (${s.time})');
      }

      // existing 完全在 candidate 裡面（例如 candidate 包含 existing）
      final existingStartsInsideCandidate = (existingStart.isAfter(candidateStart) || existingStart.isAtSameMomentAs(candidateStart)) && existingStart.isBefore(candidateEnd);
      final existingEndsInsideCandidate = existingEnd.isAfter(candidateStart) && (existingEnd.isBefore(candidateEnd) || existingEnd.isAtSameMomentAs(candidateEnd));
      if (existingStartsInsideCandidate || existingEndsInsideCandidate) {
        // 這個情況 candidate 的開始或結束不一定落在 existing 內，但區間仍重疊，標為 generic
        genericConflicts.add('${s.desc} (${s.time})');
      }
    }

    // 組合訊息，優先指出開始/結束是哪個重疊
    if (startConflicts.isNotEmpty || endConflicts.isNotEmpty || genericConflicts.isNotEmpty) {
      final parts = <String>[];
      if (startConflicts.isNotEmpty) {
        parts.add('開始時間與現有行程重疊：${startConflicts.join('；')}');
      }
      if (endConflicts.isNotEmpty) {
        parts.add('結束時間與現有行程重疊：${endConflicts.join('；')}');
      }
      if (genericConflicts.isNotEmpty && startConflicts.isEmpty && endConflicts.isEmpty) {
        parts.add('行程與現有行程區間重疊：${genericConflicts.join('；')}');
      }

      return parts.join('\n');
    }

    return null;
  }
}