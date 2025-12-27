//AI 輸入區塊組件
//提供文本輸入框讓用戶描述行程需求，支持動畫展開和收合，以及提交按鈕
import 'package:flutter/material.dart';

class AIInputSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isExpanded;
  final bool isLoading;
  final Function(String) onFetchRecommendation;
  final VoidCallback onExpandInput;

  const AIInputSection({
    super.key,
    required this.controller,
    required this.isExpanded,
    required this.isLoading,
    required this.onFetchRecommendation,
    required this.onExpandInput,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "描述您的需求",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isExpanded)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onExpandInput,
                      tooltip: "重新編輯需求",
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (isExpanded) ...[
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "例如：安排一個包含工作、運動和休閒的平衡行程",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => onFetchRecommendation(controller.text),
                    icon: isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                    label: Text(isLoading ? "AI 思考中..." : "獲取 AI 推薦"),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    controller.text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}