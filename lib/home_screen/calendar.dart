// ignore_for_file: avoid_print

import 'package:data_transmit/schedule_creation/manual_schedule_page_temp.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'custom_bottom_app_bar.dart';
import '../schedule_creation/schedule_creation_page.dart';
import '../ai_recommendation/ai_recommendation_page.dart';

// 導入分離的組件
import 'models/schedule_item.dart';
import 'services/calendar_firebase_service.dart';
import 'widgets/custom_calendar_widget.dart';
import '../../shared/widgets/schedule_list_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ScheduleItem> scheduleList = [];
  bool isLoading = false;
  
  // 格式狀態控制
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 從 Firebase 取得行程
  Future<void> _loadSchedules() async {
    if (_selectedDay == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final schedules = await CalendarFirebaseService.loadSchedules(_selectedDay!);
      setState(() {
        scheduleList = schedules;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        scheduleList = [];
      });
    }
  }

  // 新增行程到 Firebase
  Future<void> addScheduleToFirebase(
    String name, 
    String desc, 
    DateTime startTime, 
    DateTime endTime,
  ) async {
    if (_selectedDay == null) return;
    
    try {
      await CalendarFirebaseService.addSchedule(
        selectedDay: _selectedDay!,
        name: name,
        desc: desc,
        startTime: startTime,
        endTime: endTime,
      );
      
      // 重新載入行程
      _loadSchedules();
      
    } catch (e) {
      // 錯誤處理可以在這裡添加用戶提示
      print('新增行程失敗：$e');
    }
  }

  // 處理選單選擇
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'add_schedule':
        // 新增行程 - 需要先選擇日期
        if (_selectedDay == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('請先選擇日期'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManualSchedulePage(
              selectedDay: _selectedDay!,
            ),
          ),
        ).then((result) {
          // 如果有新增行程，重新載入
          if (result == true) {
            _loadSchedules();
          }
        });
        break;
      case 'add_schedule_auto_time_selected':
        // 新增自由行程 - 使用原本的 ScheduleCreationPage
        final targetDate = _selectedDay ?? DateTime.now();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleCreationPage(
              selectedDay: targetDate,
            ),
          ),
        ).then((_) {
          // 返回後重新載入行程
          if (_selectedDay != null) {
            _loadSchedules();
          }
        });
        break;
      case 'ai_recommend':
        // AI 推薦行程 - 會自動處理未選擇日期的情況
        _showAIRecommendations();
        break;
      case 'ai_optimize':
        // AI 優化時間邏輯
        print('AI 優化時間');
        break;
      case 'quick_templates':
        // 使用快速模板邏輯
        print('使用快速模板');
        break;
      case 'import_calendar':
        // 匯入行程邏輯
        print('匯入行程');
        break;
      default:
        break;
    }
  }

  void _showAIRecommendations() {
    // 如果沒有選擇日期，使用當天日期
    final targetDate = _selectedDay ?? DateTime.now();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIRecommendationPage(
          selectedDate: targetDate,
          onSchedulesSelected: (schedules) {
            // 處理返回的行程數據
            _addSchedulesFromAI(schedules, targetDate);
          },
        ),
      ),
    );
  }

  // 修改 _addSchedulesFromAI 方法，接受目標日期參數
  void _addSchedulesFromAI(List<Map<String, dynamic>> schedules, DateTime targetDate) {
    // 這裡可以將 AI 推薦的行程加入到日曆中
    for (final schedule in schedules) {
      // 創建行程的邏輯
      print('Adding schedule: ${schedule['name']} at ${schedule['startTime']} on ${targetDate.toString()}');
    }
    
    // 如果目標日期不是當前選擇的日期，需要更新選擇的日期
    if (_selectedDay?.day != targetDate.day || 
        _selectedDay?.month != targetDate.month || 
        _selectedDay?.year != targetDate.year) {
      setState(() {
        _selectedDay = targetDate;
        _focusedDay = targetDate;
      });
    }
    
    // 重新載入行程
    _loadSchedules();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已套用 ${schedules.length} 個 AI 推薦行程')),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行事曆')),
      body: Column(
        children: [
          CustomCalendarWidget(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                scheduleList.clear();
              });
              _loadSchedules();
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          const SizedBox(height: 20),
          if (_selectedDay != null)
            Expanded(
              child: ScheduleListWidget(
                selectedDay: _selectedDay!,
                scheduleList: scheduleList,
                isLoading: isLoading,
              ),
            ),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
        tooltip: '快速操作',
        //enabled: _selectedDay != null, // 只有選擇日期時才啟用
        position: PopupMenuPosition.over,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'add_schedule',
            child: ListTile(
              leading: Icon(Icons.event_note, color: Colors.blue),
              title: Text('新增行程'),
              subtitle: Text('親自安排行程'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'add_schedule_auto_time_selected',
            child: ListTile(
              leading: Icon(Icons.event_note, color: Colors.blue),
              title: Text('新增自由行程'),
              subtitle: Text('手動創建新的行程交由AI安排時間'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'ai_recommend',
            child: ListTile(
              leading: Icon(Icons.auto_awesome, color: Colors.purple),
              title: Text('AI 推薦行程'),
              subtitle: Text('根據您的習慣智能推薦'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          /*待開發功能
          const PopupMenuItem<String>(
            value: 'ai_optimize',
            child: ListTile(
              leading: Icon(Icons.tune, color: Colors.orange),
              title: Text('AI 優化時間'),
              subtitle: Text('優化當天行程安排'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'quick_templates',
            child: ListTile(
              leading: Icon(Icons.dashboard_customize, color: Colors.green),
              title: Text('快速模板'),
              subtitle: Text('使用預設行程模板'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'import_calendar',
            child: ListTile(
              leading: Icon(Icons.file_download, color: Colors.teal),
              title: Text('匯入行程'),
              subtitle: Text('從其他日曆匯入'),
              contentPadding: EdgeInsets.zero,
            ),
          ),*/
        ],
        onSelected: (String value) {
          _handleMenuSelection(value);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: const CustomBottomAppBar(
        color: Colors.transparent,
        fabLocation: FloatingActionButtonLocation.endDocked,
        shape: CircularNotchedRectangle(),
      ),
    );
  }
}
