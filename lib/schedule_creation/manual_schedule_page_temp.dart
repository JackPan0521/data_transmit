import 'package:flutter/material.dart';

import '../home_screen/custom_bottom_app_bar.dart';
import '../home_screen/models/schedule_item.dart';
import '../shared/widgets/schedule_list_widget.dart';
import 'services/manual_schedule_service.dart';
import 'utils/time_utils.dart';
import 'widgets/manual_schedule_form.dart';

class ManualSchedulePage extends StatefulWidget {
  final DateTime selectedDay;

  const ManualSchedulePage({
    super.key, 
    required this.selectedDay,
  });

  @override
  State<ManualSchedulePage> createState() => _ManualSchedulePageState();
}

class _ManualSchedulePageState extends State<ManualSchedulePage> {
  // 表單控制器
  final _descriptionController = TextEditingController();
  
  // 時間選擇變數
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _currentSelectionHasOverlap = false;
  
  // 狀態變數
  bool _isLoading = false;
  List<ScheduleItem> scheduleList = [];
  bool isLoadingSchedules = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultTimes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedules();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 初始化預設時間
  void _initializeDefaultTimes() {
    final now = TimeOfDay.now();
    _selectedStartTime = now;
    _selectedEndTime = TimeUtils.adjustEndTime(now);
  }

  // 載入行程列表
  Future<void> _loadSchedules() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingSchedules = true;
    });
    
    try {
      final schedules = await ManualScheduleService.loadSchedules(widget.selectedDay);
      if (mounted) {
        setState(() {
          scheduleList = schedules;
          isLoadingSchedules = false;
        });
        // 更新重疊旗標（如果 start/end 已有選擇）
        _updateOverlapFlag();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          scheduleList = [];
          isLoadingSchedules = false;
        });
        _showSnackBar('載入行程失敗：$e', Colors.red);
      }
    }
  }

  // 新增行程
  Future<void> _addManualSchedule() async {
    // 輸入驗證
    final inputError = ManualScheduleService.validateInput(
      description: _descriptionController.text,
      startTime: _selectedStartTime,
      endTime: _selectedEndTime,
    );

    if (inputError != null) {
      _showSnackBar(inputError, Colors.orange);
      return;
    }

    final startDateTime = ManualScheduleService.createDateTime(
      selectedDay: widget.selectedDay,
      time: _selectedStartTime!,
    );
    
    final endDateTime = ManualScheduleService.createDateTime(
      selectedDay: widget.selectedDay,
      time: _selectedEndTime!,
    );

    // 時間邏輯驗證
    final timeError = ManualScheduleService.validateTimeLogic(
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );

    if (timeError != null) {
      _showSnackBar(timeError, Colors.red);
      return;
    }

    // 檢查是否與現有行程重疊（開始/結束是否覆蓋到其他行程）
    final overlapMsg = ManualScheduleService.checkOverlapWithExisting(
      existingSchedules: scheduleList,
      candidateStart: startDateTime,
      candidateEnd: endDateTime,
    );

    if (overlapMsg != null) {
      _showSnackBar(overlapMsg, Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ManualScheduleService.addSchedule(
        selectedDay: widget.selectedDay,
        description: _descriptionController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
      );

      if (mounted) {
        _showSnackBar('行程新增成功！', Colors.green);
        _descriptionController.clear();
        await _loadSchedules();
      }

    } catch (e) {
      if (mounted) {
        _showSnackBar('新增失敗：$e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 選擇開始時間
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedStartTime = picked;
        
        // 智能調整結束時間
        if (TimeUtils.shouldAdjustEndTime(picked, _selectedEndTime)) {
          _selectedEndTime = TimeUtils.adjustEndTime(picked);
        }
      });
      // 更新重疊提示
      _updateOverlapFlag();
    }
  }

  // 選擇結束時間
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24, 
        minute: TimeOfDay.now().minute,
      ),
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedEndTime = picked;
      });
      // 更新重疊提示
      _updateOverlapFlag();
    }
  }

  // 更新目前開始/結束時間是否與現有行程重疊的旗標
  void _updateOverlapFlag() {
    if (_selectedStartTime == null || _selectedEndTime == null) {
      if (mounted) setState(() => _currentSelectionHasOverlap = false);
      return;
    }

    final startDateTime = ManualScheduleService.createDateTime(
      selectedDay: widget.selectedDay,
      time: _selectedStartTime!,
    );
    final endDateTime = ManualScheduleService.createDateTime(
      selectedDay: widget.selectedDay,
      time: _selectedEndTime!,
    );

    final overlapMsg = ManualScheduleService.checkOverlapWithExisting(
      existingSchedules: scheduleList,
      candidateStart: startDateTime,
      candidateEnd: endDateTime,
    );

    if (mounted) setState(() => _currentSelectionHasOverlap = overlapMsg != null);
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("新增行程"),
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 使用分離的表單組件
                      ManualScheduleForm(
                        descriptionController: _descriptionController,
                        selectedStartTime: _selectedStartTime,
                        selectedEndTime: _selectedEndTime,
                        highlightOverlap: _currentSelectionHasOverlap,
                        isLoading: _isLoading,
                        onSelectStartTime: _selectStartTime,
                        onSelectEndTime: _selectEndTime,
                        onAddSchedule: _addManualSchedule,
                      ),
                      const SizedBox(height: 30),
                      _buildScheduleListSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomAppBar(
        color: Colors.transparent,
        fabLocation: FloatingActionButtonLocation.endDocked,
        shape: CircularNotchedRectangle(),
      ),
    );
  }

  Widget _buildScheduleListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '今日行程',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(
            minHeight: 100,
            maxHeight: 400,
          ),
          child: ScheduleListWidget(
            selectedDay: widget.selectedDay,
            scheduleList: scheduleList,
            isLoading: isLoadingSchedules,
          ),
        ),
      ],
    );
  }
}