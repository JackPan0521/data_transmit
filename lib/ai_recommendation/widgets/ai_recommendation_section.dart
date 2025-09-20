import 'package:flutter/material.dart';

class AIRecommendationSection extends StatelessWidget {
  final String recommendation;
  final bool isExpanded;

  const AIRecommendationSection({
    super.key,
    required this.recommendation,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(isExpanded ? 16.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.blue.shade600,
                    size: isExpanded ? 24 : 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "AI 推薦理由",
                    style: TextStyle(
                      fontSize: isExpanded ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendation,
                style: TextStyle(fontSize: isExpanded ? 14 : 12),
                maxLines: isExpanded ? null : 3,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}