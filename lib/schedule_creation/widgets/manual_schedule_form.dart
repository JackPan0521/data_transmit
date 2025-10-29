import 'package:flutter/material.dart';

class ManualScheduleForm extends StatelessWidget {
  final TextEditingController descriptionController;
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final bool highlightOverlap;
  final bool isLoading;
  final VoidCallback onSelectStartTime;
  final VoidCallback onSelectEndTime;
  final VoidCallback onAddSchedule;

  const ManualScheduleForm({
    super.key,
    required this.descriptionController,
    required this.selectedStartTime,
    required this.selectedEndTime,
    this.highlightOverlap = false,
    required this.isLoading,
    required this.onSelectStartTime,
    required this.onSelectEndTime,
    required this.onAddSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '新增行程',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // 行程內容輸入
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '行程內容 *',
                hintText: '請輸入要做什麼事情，例如：開會、運動、用餐...',
                prefixIcon: Icon(Icons.event_note),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLines: 3,
              maxLength: 200,
              autofocus: true,
            ),
            const SizedBox(height: 20),
            
            // 時間選擇區塊
            _TimeSelectionWidget(
              selectedStartTime: selectedStartTime,
              selectedEndTime: selectedEndTime,
              onSelectStartTime: onSelectStartTime,
              onSelectEndTime: onSelectEndTime,
              highlightOverlap: highlightOverlap,
            ),
            const SizedBox(height: 30),
            
            // 新增按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onAddSchedule,
                icon: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_circle),
                label: Text(isLoading ? '新增中...' : '新增行程'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSelectionWidget extends StatelessWidget {
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final VoidCallback onSelectStartTime;
  final VoidCallback onSelectEndTime;
  final bool highlightOverlap;

  const _TimeSelectionWidget({
    required this.selectedStartTime,
    required this.selectedEndTime,
    required this.onSelectStartTime,
    required this.onSelectEndTime,
    this.highlightOverlap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '選擇時間 *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimeSelector(
                label: '開始時間',
                time: selectedStartTime,
                onTap: onSelectStartTime,
                icon: Icons.access_time,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TimeSelector(
                label: '結束時間',
                time: selectedEndTime,
                onTap: onSelectEndTime,
                icon: Icons.schedule,
              ),
            ),
          ],
        ),
        if (selectedStartTime != null && selectedEndTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: highlightOverlap ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: highlightOverlap ? Colors.red.shade300 : Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 16, color: highlightOverlap ? Colors.red.shade700 : Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '持續時間：${_calculateDuration(selectedStartTime!, selectedEndTime!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: highlightOverlap ? Colors.red.shade700 : Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;
    
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }
    
    final durationMinutes = endMinutes - startMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      // ignore: unnecessary_brace_in_string_interps
      return '${hours}小時${minutes}分鐘';
    } else if (hours > 0) {
      return '$hours小時';
    } else {
      return '$minutes分鐘';
    }
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final IconData icon;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    time?.format(context) ?? '選擇時間',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}