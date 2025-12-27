//AI 推薦行程頁面
//主要功能：讓用戶輸入行程需求，與後端 AI 服務通信獲取推薦行程，用戶可選擇和編輯推薦的任務，最後套用到日程表
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 導入分離的組件
import 'widgets/ai_input_section.dart';
import 'widgets/ai_recommendation_section.dart';
import 'widgets/selected_tasks_section.dart';
import 'widgets/available_tasks_section.dart';
import 'services/ai_recommendation_service.dart';
import 'models/task_model.dart';

class AIRecommendationPage extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<Map<String, dynamic>>)? onSchedulesSelected;

  const AIRecommendationPage({
    super.key,
    required this.selectedDate,
    this.onSchedulesSelected,
  });

  @override
  State<AIRecommendationPage> createState() => _AIRecommendationPageState();
}

class _AIRecommendationPageState extends State<AIRecommendationPage> {
  final TextEditingController _controller = TextEditingController();
  final AIRecommendationService _aiService = AIRecommendationService();
  
  String? recommendation;
  Map<String, dynamic>? planJson;
  bool isLoading = false;
  List<TaskModel> selectedTasks = [];
  bool _isInputExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller.text = _generateDefaultQuery();
  }

  String _generateDefaultQuery() {
    final weekday = _getWeekdayName(widget.selectedDate.weekday);
    final dateStr = "${widget.selectedDate.year}/${widget.selectedDate.month}/${widget.selectedDate.day}";
    return "請為我安排 $dateStr ($weekday) 的一日行程";
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekdays[weekday - 1]}';
  }

  bool _isToday() {
    final today = DateTime.now();
    return widget.selectedDate.year == today.year &&
           widget.selectedDate.month == today.month &&
           widget.selectedDate.day == today.day;
  }

  /// 獲取 AI 推薦
  Future<void> _fetchAIRecommendation(String question) async {
    setState(() => isLoading = true);

    try {
      final result = await _aiService.getRecommendation(question);
      
      if (!mounted) return;

      setState(() {
        recommendation = result['recommendation'];
        planJson = result['planJson'];
        isLoading = false;
        _isInputExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        recommendation = "獲取推薦失敗：$e";
        planJson = null;
        isLoading = false;
      });
    }
  }

  /// 選擇任務時間
  Future<void> _selectTaskTime(Map<String, dynamic> taskData, {int? existingIndex}) async {
    final result = await TaskModel.selectTimeForTask(
      context: context,
      taskData: taskData,
      defaultDate: widget.selectedDate, // 作為 fallback 日期
    );

    if (result != null && mounted) {
      setState(() {
        if (existingIndex != null) {
          selectedTasks[existingIndex] = result;
        } else {
          selectedTasks.add(result);
        }
      });
      
      final dateStr = result.formattedDate;
      final weekday = result.weekdayName;
      _showMessage("已${existingIndex != null ? '更新' : '選擇'} ${result.eventName} 至 $dateStr ($weekday)");
    }
  }

  /// 移除任務
  void _removeTask(int index) {
    if (mounted) {
      setState(() => selectedTasks.removeAt(index));
      _showMessage("已移除行程");
    }
  }

  /// 套用選擇的行程
  void _applySelectedSchedules() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showMessage("請先登入以使用此功能");
      return;
    }

    if (selectedTasks.isEmpty) {
      _showMessage("請先選擇要套用的行程");
      return;
    }

    try {
      // 上傳數據到後端（移除 selectedDate 參數）
      await _aiService.submitScheduleData(
        selectedTasks: selectedTasks,
        planJson: planJson,
        userId: currentUser.uid, selectedDate: widget.selectedDate,
      );

      // 轉換格式並回調
      final schedulesToAdd = selectedTasks.map((task) => task.toScheduleFormat()).toList();

      if (widget.onSchedulesSelected != null) {
        widget.onSchedulesSelected!(schedulesToAdd);
      }

      // 計算涉及的日期數量
      final uniqueDates = selectedTasks.map((task) => task.formattedDate).toSet();
      final daysCount = uniqueDates.length;

      if (mounted) {
        _showMessage("✅ 已同步 $daysCount 天的行程到雲端並完成自動排程");
        Navigator.pop(context, schedulesToAdd);
      }
    } catch (e) {
      _showMessage("同步失敗：$e");
    }
  }

  /// 重新展開輸入區域
  void _expandInput() {
    setState(() {
      _isInputExpanded = true;
      recommendation = null;
      planJson = null;
      selectedTasks.clear();
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${widget.selectedDate.year}/${widget.selectedDate.month}/${widget.selectedDate.day}";
    final weekday = _getWeekdayName(widget.selectedDate.weekday);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("AI 推薦行程"),
            Text(
              "$dateStr ($weekday)${_isToday() ? ' - 今天' : ''}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        // 移除 actions 部分
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 輸入區域
            AIInputSection(
              controller: _controller,
              isExpanded: _isInputExpanded,
              isLoading: isLoading,
              onFetchRecommendation: _fetchAIRecommendation,
              onExpandInput: _expandInput,
            ),

            const SizedBox(height: 12),

            // AI 推薦說明
            if (recommendation != null) ...[
              AIRecommendationSection(
                recommendation: recommendation!,
                isExpanded: _isInputExpanded,
              ),
              const SizedBox(height: 12),
            ],

            // 已選擇的行程
            if (selectedTasks.isNotEmpty) ...[
              SelectedTasksSection(
                selectedTasks: selectedTasks,
                onEditTask: _selectTaskTime,
                onRemoveTask: _removeTask,
              ),
              const SizedBox(height: 12),
            ],

            // 可選擇的行程清單
            if (planJson != null)
              Expanded(
                child: AvailableTasksSection(
                  planJson: planJson!,
                  selectedTasks: selectedTasks,
                  onSelectTask: _selectTaskTime,
                  onApplySchedules: _applySelectedSchedules,
                ),
              ),
          ],
        ),
      ),
    );
  }
}