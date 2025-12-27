//Firebase 路徑管理器
//主要功能：集中管理所有 Firebase Firestore 的路徑結構，確保整應用中路徑一致
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase 路徑管理器
/// 集中管理所有 Firebase 路徑結構，確保一致性
class FirebasePaths {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 獲取當前用戶 ID
  static String get currentUserId {
    return _auth.currentUser?.uid ?? '';
  }

  /// 檢查用戶是否已登入
  static bool get isUserLoggedIn {
    return currentUserId.isNotEmpty;
  }

  /// 獲取日期文檔路徑 (Task/{userId}/task_list/{date})
  static DocumentReference dateDocument(FirebaseFirestore firestore, String dateString) {
    return firestore
        .collection('Tasks')
        .doc(currentUserId)
        .collection('task_list')
        .doc(dateString);
  }

  /// 獲取日期任務集合路徑 (Task/{userId}/task_list/{date}/tasks)
  static CollectionReference tasksCollection(FirebaseFirestore firestore, String dateString) {
    return dateDocument(firestore, dateString).collection('tasks');
  }

  /// 獲取特定任務文檔路徑 (Task/{userId}/task_list/{date}/tasks/{taskId})
  static DocumentReference taskDocument(
      FirebaseFirestore firestore, String dateString, String taskId) {
    return tasksCollection(firestore, dateString).doc(taskId);
  }

  /// 生成任務 ID (task_{number})
  static String generateTaskId(int taskNumber) {
    return 'task_$taskNumber';
  }

  /// 檢查並創建日期文檔（如果不存在）
  static Future<void> ensureDateDocumentExists(
      FirebaseFirestore firestore, String dateString) async {
    final docRef = dateDocument(firestore, dateString);
    final snapshot = await docRef.get();
    
    if (!snapshot.exists) {
      await docRef.set({
        'date': dateString,
        'created_at': Timestamp.now(),
      });
    }
  }
}

/// 數據加載器
/// 負責加載任務數據
class DataLoader {
  final FirebaseFirestore _firestore;

  DataLoader(this._firestore);

  /// 加載指定日期的任務數據
  Future<void> loadData(String dateString) async {
    // 檢查用戶登入
    if (!FirebasePaths.isUserLoggedIn) {
      throw Exception('使用者未登入');
    }
    
    // 確保文檔存在
    await FirebasePaths.ensureDateDocumentExists(_firestore, dateString);
  }
}