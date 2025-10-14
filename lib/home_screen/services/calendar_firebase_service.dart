// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase 行程管理服務
class CalendarFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 獲取當前用戶 UID，如果未登入則返回空字符串
  static String get _currentUserId {
    return _auth.currentUser?.uid ?? '';
  }

  /// 從 Firebase 載入指定日期的行程
  static Future<List<ScheduleItem>> loadSchedules(DateTime selectedDay) async {
    try {
      // 檢查是否有用戶登入
      if (_currentUserId.isEmpty) {
        throw Exception('使用者未登入');
      }
      
      // 生成日期格式字符串: yyyy-MM-dd
      final dateString = generateDateString(selectedDay);
      
      // 建構新的文檔路徑: Tasks/uid/task_list/year-month-day/tasks
      final basePath = 'Tasks/$_currentUserId/task_list/$dateString';
      
      // 讀取 tasks 集合
      final snapshot = await _firestore
          .doc(basePath)
          .collection('tasks')
          .get();
    
      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          return ScheduleItem.fromFirebaseDoc(data, doc.id);
        }).toList();
        
        // 客戶端智能排序
        list.sort((a, b) {
          final aTime = a.sortableDateTime;
          final bTime = b.sortableDateTime;
          
          // 如果都有解析成功的時間，按時間排序
          if (aTime != null && bTime != null) {
            return aTime.compareTo(bTime);
          }
          
          // 如果時間解析失敗，嘗試按字符串排序
          if (a.startTime.isNotEmpty && b.startTime.isNotEmpty) {
            return a.startTime.compareTo(b.startTime);
          }
          
          // 如果只有一個有時間，有時間的排在前面
          if (aTime != null || a.startTime.isNotEmpty) return -1;
          if (bTime != null || b.startTime.isNotEmpty) return 1;
          
          // 最後按 index 排序
          return a.index.compareTo(b.index);
        });
        
        return list;
        
      } else {
        return [];
      }
      
    } catch (e) {
      print('載入行程失敗: $e');
      rethrow;
    }
  }

  /// 新增行程到 Firebase
  static Future<void> addSchedule({
    required DateTime selectedDay,
    required String name,
    required String desc,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // 檢查是否有用戶登入
      if (_currentUserId.isEmpty) {
        throw Exception('使用者未登入');
      }
      
      // 生成日期格式字符串
      final dateString = generateDateString(selectedDay);
      
      // 新路徑格式
      final basePath = 'Tasks/$_currentUserId/task_list/$dateString';
      
      // 先取得目前的行程數量來決定 task_number
      final existingTasks = await _firestore
          .doc(basePath)
          .collection('tasks')
          .get();
    
      final newTaskNumber = existingTasks.docs.length + 1;
      
      // 新增行程
      await _firestore
          .doc(basePath)
          .collection('tasks')
          .doc('$newTaskNumber') // 只使用數字格式 1, 2, 3...
          .set({
        'name': name,
        'desc': desc,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'index': newTaskNumber - 1,
      });
      
    } catch (e) {
      print('新增行程失敗: $e');
      rethrow;
    }
  }

  /// 生成日期字符串，格式為 yyyy-MM-dd
  static String generateDateString(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 生成完整路徑字符串
  static String generateFullPath(DateTime date) {
    if (_currentUserId.isEmpty) {
      throw Exception('使用者未登入');
    }
    final dateString = generateDateString(date);
    return 'Tasks/$_currentUserId/task_list/$dateString';
  }
}
