import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../../home_screen/services/calendar_firebase_service.dart';
import 'edit_schedule_dialog.dart';

/// 行程操作對話框工具類
class ScheduleActionsDialog {
  final BuildContext context;
  final ScheduleService _scheduleService = ScheduleService();

  ScheduleActionsDialog(this.context);

  /// 顯示行程選項對話框（查看詳情、編輯、刪除）
  void showScheduleOptionsDialog(
    ScheduleModel schedule, 
    DateTime selectedDate,
    {VoidCallback? onUpdated}
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          schedule.name.isNotEmpty ? schedule.name : '行程',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 時間資訊
            if (schedule.startTime != null && schedule.endTime != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatTime(schedule.startTime!)} - ${_formatTime(schedule.endTime!)}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (schedule.startTime != null && schedule.endTime != null)
              const SizedBox(height: 12),

            // 描述
            const Text('描述:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              schedule.description.isNotEmpty ? schedule.description : '無描述',
              style: TextStyle(
                color: schedule.description.isNotEmpty ? Colors.black87 : Colors.grey.shade600,
                fontStyle: schedule.description.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showEditScheduleDialog(
                context,
                schedule: schedule,
                selectedDate: selectedDate,
                onScheduleUpdated: onUpdated ?? () {},
              );
            },
            child: const Text('編輯'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmDialog(schedule, selectedDate, onUpdated);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  /// 顯示刪除確認對話框
  void _showDeleteConfirmDialog(
    ScheduleModel schedule, 
    DateTime selectedDate,
    VoidCallback? onDeleted,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除行程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '確定要刪除這個行程嗎？',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                schedule.description.isNotEmpty ? schedule.description : '無描述行程',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '此操作無法復原',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _deleteSchedule(context, schedule, selectedDate, onDeleted),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );
  }

  /// 執行刪除行程
  Future<void> _deleteSchedule(
    BuildContext context,
    ScheduleModel schedule,
    DateTime selectedDate,
    VoidCallback? onDeleted,
  ) async {
    // 關閉確認對話框
    Navigator.of(context).pop();
    
    // 顯示載入對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在刪除...'),
          ],
        ),
      ),
    );

    try {
      // 產生日期字符串
      final dateString = CalendarFirebaseService.generateDateString(selectedDate);
      
      // 調用刪除服務
      await _scheduleService.deleteSchedule(
        dateString,
        selectedDate,
        schedule.id,
      );

      if (!context.mounted) return;

      // 關閉載入對話框
      Navigator.of(context).pop();

      // 顯示成功訊息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('行程已成功刪除！'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      // 通知父級更新
      onDeleted?.call();

    } catch (e) {
      if (!context.mounted) return;
      
      // 關閉載入對話框
      Navigator.of(context).pop();

      // 顯示錯誤訊息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('刪除失敗：${_getErrorMessage(e)}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// 格式化時間顯示
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 錯誤訊息處理
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('not-found') || errorStr.contains('document does not exist')) {
      return '行程不存在或已被刪除';
    } else if (errorStr.contains('permission') || errorStr.contains('unauthorized')) {
      return '沒有權限執行此操作';
    } else if (errorStr.contains('network') || errorStr.contains('timeout')) {
      return '網路連線問題，請檢查網路';
    } else if (errorStr.contains('使用者未登入')) {
      return '請先登入';
    } else {
      return '操作失敗，請稍後再試';
    }
  }
}