//行程創建頁面
//主要功能：提供手動創建行程的界面，用戶輸入行程基本信息（時間、名稱等），並與後端通信保存到 Firebase
import 'package:data_transmit/widget.dart';
import 'package:flutter/material.dart';

import 'services/schedule_creation_service.dart';
import '../home_screen/custom_bottom_app_bar.dart';
import '../shared/services/firebase_service.dart';
import '../shared/services/network_service.dart';

class ScheduleCreationPage extends StatefulWidget {
  final DateTime? selectedDay;

  const ScheduleCreationPage({super.key, this.selectedDay});

  @override
  State<ScheduleCreationPage> createState() => _ScheduleCreationPageState();
}

class _ScheduleCreationPageState extends State<ScheduleCreationPage> {
  bool isReconnecting = false;
  int retryCount = 0;
  String responseMsg = '';
  
  late final ScheduleCreationService _scheduleService;
  late final NetworkService _networkService;

  @override
  void initState() {
    super.initState();
    _scheduleService = ScheduleCreationService();
    _networkService = NetworkService();
  }

  Future<void> _sendToBackend(Map<String, dynamic> data) async {
    setState(() {
      isReconnecting = true;
      retryCount = 0;
    });

    final result = await _networkService.sendData(data);
    
    setState(() {
      isReconnecting = false;
      retryCount = result['retryCount'] ?? 0;
      responseMsg = result['message'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.selectedDay ?? DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("今天有什麼行程？"),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              InputSection(
                onSubmit: _sendToBackend,
                selectedDay: selectedDate,
              ),
              const SizedBox(height: 20),
              _buildStatusSection(),
              const SizedBox(height: 20),
              _buildScheduleList(selectedDate),
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

  Widget _buildStatusSection() {
    return Column(
      children: [
        if (isReconnecting)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "正在重新連接... 第 $retryCount 次",
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        if (!isReconnecting && responseMsg.isNotEmpty) // ← 只在不重連時顯示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isSuccessMessage(responseMsg) 
                  ? Colors.green.shade50 
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSuccessMessage(responseMsg) 
                    ? Colors.green.shade300 
                    : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSuccessMessage(responseMsg) 
                      ? Icons.check_circle 
                      : Icons.error,
                  color: _isSuccessMessage(responseMsg) 
                      ? Colors.green.shade700 
                      : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatMessage(responseMsg),
                    style: TextStyle(
                      color: _isSuccessMessage(responseMsg) 
                          ? Colors.green.shade700 
                          : Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 判斷是否為成功訊息（改進版：解析 JSON）
  bool _isSuccessMessage(String msg) {
    // 嘗試解析 JSON 格式的 success 欄位
    if (msg.contains('"success"')) {
      final successMatch = RegExp(r'"success"\s*:\s*(true|false)').firstMatch(msg);
      if (successMatch != null) {
        return successMatch.group(1) == 'true';
      }
    }
    
    // 備用判斷（若不是 JSON 格式）
    return msg.contains('成功') || 
           msg.contains('✅') || 
           msg.toLowerCase().contains('success');
  }

  // 格式化訊息（移除 JSON 格式，只保留友善文字）
  String _formatMessage(String msg) {
    // 若訊息包含 JSON 格式，嘗試提取 message 欄位
    if (msg.contains('"message"')) {
      final messageMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(msg);
      if (messageMatch != null) {
        return messageMatch.group(1) ?? msg;
      }
    }
    
    // 備用：移除多餘的 JSON 符號（若 regex 失敗）
    return msg
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('"', '')
        .replaceAll('success:true,', '')
        .replaceAll('success:false,', '')
        .replaceAll('message:', '')
        .trim();
  }

  Widget _buildScheduleList(DateTime selectedDate) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseService.getSchedules(selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            color: Colors.blue.shade600,
          );
        } else if (snapshot.hasError) {
          return Text(
            '讀取失敗：${snapshot.error}',
            style: TextStyle(color: Colors.red.shade600),
          );
        }

        final scheduleList = snapshot.data ?? [];

        // 直接交給 service 處理 filter/sort
        return _scheduleService.buildScheduleListWidget(
          scheduleList,
          selectedDate,
          context,
        );
      },
    );
  }
}