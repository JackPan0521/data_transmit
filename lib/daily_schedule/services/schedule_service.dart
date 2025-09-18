import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import '../models/schedule_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 獲取當前用戶 UID，如果未登入則返回空字符串
  String get _currentUserId {
    return _auth.currentUser?.uid ?? '';
  }

  /// 讀取某天所有行程
  Future<List<ScheduleModel>> loadDaySchedules(String dateString, DateTime selectedDate) async {
    try {
      // 檢查用戶是否已登入
      if (_currentUserId.isEmpty) {
        throw Exception('使用者未登入');
      }

      developer.log('🔍 載入日行程：$dateString');

      // 使用新的路徑格式獲取文檔
      final snapshot = await _firestore
          .collection('Tasks')
          .doc(_currentUserId)
          .collection('task_list')
          .doc(dateString)
          .collection('tasks')
          .get();

      final List<ScheduleModel> schedules = [];

      for (var doc in snapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          
          // 從 Firestore 文檔中獲取時間資料
          DateTime? startTime;
          DateTime? endTime;
          
          // 處理 startTime - 支援多種格式
          final startData = data['startTime'];
          if (startData is Timestamp) {
            startTime = startData.toDate();
          } else if (startData is String) {
            try {
              if (startData.contains('T') || startData.contains('-')) {
                // 完整日期時間格式，例如 "2025-09-18T12:00:00"
                startTime = DateTime.parse(startData);
              } else if (startData.contains(':')) {
                // 只有時間部分，例如 "12:00"
                final timeParts = startData.split(':');
                if (timeParts.length >= 2) {
                  final hour = int.tryParse(timeParts[0]) ?? 0;
                  final minute = int.tryParse(timeParts[1]) ?? 0;
                  startTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    hour,
                    minute,
                  );
                }
              }
            } catch (e) {
              developer.log('⚠️ 無法解析 startTime 字符串: $startData，錯誤: $e');
            }
          }
          
          // 處理 endTime - 支援多種格式
          final endData = data['endTime'];
          if (endData is Timestamp) {
            endTime = endData.toDate();
          } else if (endData is String) {
            try {
              if (endData.contains('T') || endData.contains('-')) {
                // 完整日期時間格式
                endTime = DateTime.parse(endData);
              } else if (endData.contains(':')) {
                // 只有時間部分，例如 "12:30"
                final timeParts = endData.split(':');
                if (timeParts.length >= 2) {
                  final hour = int.tryParse(timeParts[0]) ?? 0;
                  final minute = int.tryParse(timeParts[1]) ?? 0;
                  endTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    hour,
                    minute,
                  );
                }
              }
            } catch (e) {
              developer.log('⚠️ 無法解析 endTime 字符串: $endData，錯誤: $e');
            }
          }
          
          schedules.add(
            ScheduleModel(
              id: doc.id,
              name: data['name'] ?? '',
              description: data['desc'] ?? '',
              startTime: startTime,
              endTime: endTime,
              hasOverlap: data['hasOverlap'] ?? false,
              index: data['index'] ?? 0,
            ),
          );
        } catch (e) {
          developer.log('⚠️ 解析行程失敗: $e，文檔ID: ${doc.id}');
        }
      }

      // 根據開始時間排序
      schedules.sort((a, b) {
        if (a.startTime == null && b.startTime == null) {
          return 0;
        } else if (a.startTime == null) {
          return 1;
        } else if (b.startTime == null) {
          return -1;
        }
        return a.startTime!.compareTo(b.startTime!);
      });

      developer.log('✅ 載入完成，共 ${schedules.length} 筆行程');
      return schedules;
    } catch (e) {
      developer.log('❌ 載入日行程失敗：$e');
      rethrow;
    }
  }

  /// 刪除行程
  Future<void> deleteSchedule(String dateString, DateTime selectedDate, String scheduleId) async {
    try {
      // 檢查用戶是否已登入
      if (_currentUserId.isEmpty) {
        throw Exception('使用者未登入');
      }

      await _firestore
          .collection('Tasks')
          .doc(_currentUserId)
          .collection('task_list')
          .doc(dateString)
          .collection('tasks')
          .doc(scheduleId)
          .delete();
      
      developer.log('✅ 行程已刪除: $scheduleId');
    } catch (e) {
      developer.log('❌ 刪除行程失敗：$e');
      rethrow;
    }
  }

  /// 更新行程
  Future<void> updateSchedule(
    String dateString, 
    DateTime selectedDate,
    String scheduleId, 
    Map<String, dynamic> data
  ) async {
    try {
      // 檢查用戶是否已登入
      if (_currentUserId.isEmpty) {
        throw Exception('使用者未登入');
      }

      await _firestore
          .collection('Tasks')
          .doc(_currentUserId)
          .collection('task_list')
          .doc(dateString)
          .collection('tasks')
          .doc(scheduleId)
          .update(data);
      
      developer.log('✅ 行程已更新: $scheduleId');
    } catch (e) {
      developer.log('❌ 更新行程失敗：$e');
      rethrow;
    }
  }
}