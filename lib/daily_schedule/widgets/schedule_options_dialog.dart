import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import 'edit_schedule_dialog.dart';
import '../services/schedule_service.dart';
import '../../home_screen/services/calendar_firebase_service.dart';

class ScheduleOptionsDialog {
  static void show(
    BuildContext context,
    ScheduleModel schedule,
    DateTime selectedDate,
    VoidCallback onScheduleUpdated,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.35,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildTitle(schedule),
              _buildTimeInfo(schedule),
              const SizedBox(height: 8),
              _buildEditOption(context, schedule, selectedDate, onScheduleUpdated),
              _buildDeleteOption(context, schedule, selectedDate, onScheduleUpdated),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static Widget _buildTitle(ScheduleModel schedule) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Text(
        schedule.name.isNotEmpty ? schedule.name : schedule.description,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Widget _buildTimeInfo(ScheduleModel schedule) {
    return Text(
      schedule.timeRange,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
      ),
    );
  }

  static Widget _buildEditOption(
    BuildContext context,
    ScheduleModel schedule,
    DateTime selectedDate,
    VoidCallback onScheduleUpdated,
  ) {
    return _buildOption(
      icon: Icons.edit,
      title: '編輯行程',
      color: Colors.blue,
      onTap: () {
        Navigator.pop(context);
        showEditScheduleDialog(
          context,
          schedule: schedule,
          selectedDate: selectedDate,
          onScheduleUpdated: onScheduleUpdated,
        );
      },
    );
  }

  static Widget _buildDeleteOption(
    BuildContext context,
    ScheduleModel schedule,
    DateTime selectedDate,
    VoidCallback onScheduleUpdated,
  ) {
    return _buildOption(
      icon: Icons.delete,
      title: '刪除行程',
      color: Colors.red,
      onTap: () async {
        Navigator.pop(context);
        
        // 顯示刪除確認對話框
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '確定要刪除這個行程嗎？',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('確定刪除'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
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
            final scheduleService = ScheduleService();
            final dateString = CalendarFirebaseService.generateDateString(selectedDate);
            
            await scheduleService.deleteSchedule(
              dateString,
              selectedDate,
              schedule.id,
            );

            if (context.mounted) {
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
              
              // 通知父組件更新
              onScheduleUpdated();
            }
          } catch (e) {
            if (context.mounted) {
              // 關閉載入對話框
              Navigator.of(context).pop();
              
              // 顯示錯誤訊息
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text('刪除失敗：$e')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
    );
  }

  static Widget _buildOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}