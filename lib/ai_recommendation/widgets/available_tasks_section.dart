import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/task_utils.dart';

class AvailableTasksSection extends StatelessWidget {
  final Map<String, dynamic> planJson;
  final List<TaskModel> selectedTasks;
  final Function(Map<String, dynamic>) onSelectTask;
  final VoidCallback onApplySchedules;

  const AvailableTasksSection({
    super.key,
    required this.planJson,
    required this.selectedTasks,
    required this.onSelectTask,
    required this.onApplySchedules,
  });

  @override
  Widget build(BuildContext context) {
    final availableTasks = planJson["行程"] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "推薦行程：${planJson["計畫名稱"] ?? ''}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (selectedTasks.isNotEmpty)
              ElevatedButton.icon(
                onPressed: onApplySchedules,
                icon: const Icon(Icons.check, size: 18),
                label: const Text("套用", style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: availableTasks.length,
            itemBuilder: (context, index) {
              final task = availableTasks[index];
              final isSelected = selectedTasks.any(
                (t) => t.eventName == task["事件"],
              );

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? Colors.green.shade50 : null,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Colors.green
                        : Colors.blue.shade100,
                    child: Icon(
                      TaskUtils.getEventIcon(task["事件"]),
                      color: isSelected
                          ? Colors.white
                          : Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    task["事件"],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    "持續時間: ${task["持續時間"]} 分鐘\n${task["多元智慧領域"]}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline),
                  onTap: isSelected ? null : () => onSelectTask(task),
                  dense: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}