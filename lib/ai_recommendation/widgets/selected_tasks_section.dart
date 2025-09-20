import 'package:flutter/material.dart';
import '../models/task_model.dart';

class SelectedTasksSection extends StatelessWidget {
  final List<TaskModel> selectedTasks;
  final Function(Map<String, dynamic>, {int? existingIndex}) onEditTask;
  final Function(int) onRemoveTask;

  const SelectedTasksSection({
    super.key,
    required this.selectedTasks,
    required this.onEditTask,
    required this.onRemoveTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "已選擇的行程 (${selectedTasks.length})",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90, // 減少高度，因為移除了文字
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedTasks.length,
            itemBuilder: (context, index) {
              final task = selectedTasks[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 8),
                child: Card(
                  color: Colors.green.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 上半部 - 行程名稱
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text(
                              task.eventName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        
                        // 中間 - 時間區段
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Text(
                            "${task.startTime} - ${task.endTime}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // 下半部 - 操作按鈕（簡化設計）
                        SizedBox(
                          height: 24, // 減少按鈕區域高度
                          child: Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => onEditTask(
                                      task.toJson(),
                                      existingIndex: index,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    child: SizedBox(
                                      height: double.infinity,
                                      child: Center( // 簡化為 Center
                                        child: Icon(
                                          Icons.edit,
                                          size: 16, // 稍微增加圖標大小
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 16,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => onRemoveTask(index),
                                    borderRadius: BorderRadius.circular(4),
                                    child: SizedBox(
                                      height: double.infinity,
                                      child: Center( // 簡化為 Center
                                        child: Icon(
                                          Icons.delete,
                                          size: 16, // 稍微增加圖標大小
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}