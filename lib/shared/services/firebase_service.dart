import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../../daily_schedule/utils/schedule_utils.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 獲取當前用戶 UID，如果未登入則返回空字符串
  static String get _currentUserId {
    return _auth.currentUser?.uid ?? '';
  }
  
  static Future<List<Map<String, dynamic>>> getSchedules(DateTime selectedDate) async {
    try {
      // 檢查是否有用戶登入
      if (_currentUserId.isEmpty) {
        throw Exception('使用者未登入');
      }
      
      final dateString = ScheduleUtils.formatDate(selectedDate);
      developer.log('🔍 載入行程列表：$dateString');
      
      // 創建日期文檔的引用
      final dateDocRef = _firestore
          .collection('Tasks')
          .doc(_currentUserId)
          .collection('task_list')
          .doc(dateString);
      
      // 檢查日期文檔是否存在
      final docSnapshot = await dateDocRef.get();
      if (!docSnapshot.exists) {
        // 如果文檔不存在，先創建空文檔
        await dateDocRef.set({
          'date': dateString,
          'created_at': Timestamp.now()
        });
        developer.log('✅ 建立新的日期文檔: $dateString');
        return [];
      }
      
      // 獲取任務集合
      final snapshot = await dateDocRef.collection('tasks').get();

      final schedules = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'desc': data['desc'] ?? data['name'] ?? '未知行程',
          'startTime': data['startTime'],
          'endTime': data['endTime'],
          'index': data['index'] ?? 0,
        };
      }).toList();

      // ✅ 按照開始時間排序
      _sortSchedulesByTime(schedules);

      developer.log('✅ 成功載入並排序 ${schedules.length} 筆行程');
      return schedules;

    } catch (e) {
      developer.log('❌ 載入行程失敗：$e');
      return [];
    }
  }

  static void _sortSchedulesByTime(List<Map<String, dynamic>> schedules) {
    // 排序邏輯保持不變
    int parseMinutes(dynamic timeValue) {
      if (timeValue == null) return 0;
      if (timeValue is Timestamp) {
        final date = timeValue.toDate();
        return date.hour * 60 + date.minute;
      }
      if (timeValue is String && timeValue.contains(':')) {
        final parts = timeValue.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0].trim()) ?? 0;
          final minute = int.tryParse(parts[1].trim()) ?? 0;
          return hour * 60 + minute;
        }
      }
      return 0;
    }

    schedules.sort((a, b) {
      final aMin = parseMinutes(a['startTime']);
      final bMin = parseMinutes(b['startTime']);
      return aMin.compareTo(bMin);
    });
  }

  static Future<void> addSchedule(DateTime selectedDate, String name, String desc, DateTime startTime, DateTime endTime) async {
    try {
      // 檢查是否有用戶登入
      if (_currentUserId.isEmpty) {
        throw Exception('使用者未登入');
      }
      
      // 生成日期格式字符串
      final dateString = ScheduleUtils.formatDate(selectedDate);
      
      // 創建日期文檔的引用
      final dateDocRef = _firestore
          .collection('Tasks')
          .doc(_currentUserId)
          .collection('task_list')
          .doc(dateString);
      
      // 檢查日期文檔是否存在
      final docSnapshot = await dateDocRef.get();
      if (!docSnapshot.exists) {
        // 如果文檔不存在，先創建空文檔
        await dateDocRef.set({
          'date': dateString,
          'created_at': Timestamp.now()
        });
        developer.log('✅ 建立新的日期文檔: $dateString');
      }
      
      // 先取得目前的行程數量來決定 task_number
      final existingTasks = await dateDocRef.collection('tasks').get();
      final newTaskNumber = existingTasks.docs.length + 1;
      
      // 新增行程
      await dateDocRef
          .collection('tasks')
          .doc('task_$newTaskNumber')
          .set({
        'name': name,
        'desc': desc,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'index': newTaskNumber - 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      developer.log('✅ 成功新增行程：$name');
    } catch (e) {
      developer.log('❌ 新增行程失敗：$e');
      rethrow;
    }
  }
}