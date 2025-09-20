import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class AIRecommendationService {
  static const String _baseUrl = "https://1b39113ffc61.ngrok-free.app/dick";

  /// 獲取 AI 推薦
  Future<Map<String, dynamic>> getRecommendation(String question) async {
    final url = Uri.parse("$_baseUrl/ask");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"question": question}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'recommendation': data["recommendation"],
        'planJson': data["result"],
      };
    } else {
      throw Exception("服務暫時無法使用，請稍後再試");
    }
  }

  /// 提交行程數據
  Future<void> submitScheduleData({
    required List<TaskModel> selectedTasks,
    required Map<String, dynamic>? planJson,
    required DateTime selectedDate,
    required String userId,
  }) async {
    if (selectedTasks.isEmpty) return;

    try {
      final submitData = {
        "計畫名稱": planJson?["計畫名稱"] ?? "AI 推薦行程",
        "已選行程": selectedTasks.map((task) {
          final taskData = task.toJson();
          taskData["uid"] = userId;
          return taskData;
        }).toList(),
      };

      final url = Uri.parse("$_baseUrl/submit");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(submitData),
      );

      if (response.statusCode != 200) {
        throw Exception("數據同步失敗");
      }
    } catch (e) {
      throw Exception("網路錯誤：無法同步數據");
    }
  }
}