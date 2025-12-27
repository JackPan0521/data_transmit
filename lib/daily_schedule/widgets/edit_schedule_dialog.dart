//行程編輯對話框
//主要功能：提供編輯行程詳情的對話框，用戶可修改行程名稱、描述、時間等，並直接保存到 Firebase
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../../home_screen/services/calendar_firebase_service.dart';

/// 簡化的行程編輯對話框
class EditScheduleDialog extends StatefulWidget {
  final ScheduleModel schedule;
  final DateTime selectedDate;
  final VoidCallback onScheduleUpdated;

  const EditScheduleDialog({
    super.key,
    required this.schedule,
    required this.selectedDate,
    required this.onScheduleUpdated,
  });

  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  late TextEditingController _descController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final ScheduleService _scheduleService = ScheduleService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // 初始化描述
    _descController = TextEditingController(text: widget.schedule.description);
    
    // 初始化開始時間，如果沒有則預設為現在時間
    if (widget.schedule.startTime != null) {
      _startTime = TimeOfDay.fromDateTime(widget.schedule.startTime!);
    } else {
      _startTime = TimeOfDay.now();
    }
    
    // 初始化結束時間，如果沒有則預設為開始時間+1小時
    if (widget.schedule.endTime != null) {
      _endTime = TimeOfDay.fromDateTime(widget.schedule.endTime!);
    } else {
      _endTime = TimeOfDay(
        hour: (_startTime.hour + 1) % 24,
        minute: _startTime.minute,
      );
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  /// 選擇開始時間
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // 如果開始時間晚於結束時間，自動調整結束時間
        if (_timeToMinutes(picked) >= _timeToMinutes(_endTime)) {
          final newEndHour = (picked.hour + 1) % 24;
          _endTime = TimeOfDay(hour: newEndHour, minute: picked.minute);
        }
      });
    }
  }

  /// 選擇結束時間
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && _timeToMinutes(picked) > _timeToMinutes(_startTime)) {
      setState(() {
        _endTime = picked;
      });
    } else if (picked != null && mounted) {
      // 顯示錯誤提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('結束時間不能早於或等於開始時間'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 將 TimeOfDay 轉換為分鐘數
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// 保存修改
  Future<void> _saveChanges() async {
    if (_descController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '請輸入行程描述';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 生成日期字符串
      final dateString = CalendarFirebaseService.generateDateString(widget.selectedDate);
      
      // 建立更新資料
      final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final updateData = {
        'name': _descController.text.trim(),  // 同時更新 name 欄位以保持一致性
        'desc': _descController.text.trim(),
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
      };

      // 調用服務更新行程
      await _scheduleService.updateSchedule(
        dateString,
        widget.selectedDate,
        widget.schedule.id,  // 使用實際的Firestore文檔ID
        updateData,
      );

      if (!mounted) return;

      // 通知父級元件更新
      widget.onScheduleUpdated();
      
      // 關閉對話框
      Navigator.of(context).pop(true);
      
      // 顯示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('行程已成功更新！'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _errorMessage = '更新失敗：$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('編輯行程'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顯示錯誤訊息
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            // 行程描述輸入框
            const Text('行程描述', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '請輸入行程描述...',
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),

            // 開始時間
            const Text('開始時間', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isLoading ? null : _selectStartTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 12),
                    Text(
                      _startTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 結束時間
            const Text('結束時間', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isLoading ? null : _selectEndTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 12),
                    Text(
                      _endTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('儲存'),
        ),
      ],
    );
  }
}

/// 顯示編輯行程對話框的便利方法
Future<bool?> showEditScheduleDialog(
  BuildContext context, {
  required ScheduleModel schedule,
  required DateTime selectedDate,
  required VoidCallback onScheduleUpdated,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EditScheduleDialog(
      schedule: schedule,
      selectedDate: selectedDate,
      onScheduleUpdated: onScheduleUpdated,
    ),
  );
}