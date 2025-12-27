//自定義底部應用欄
//提供應用主要功能的導航按鈕，包括新增行程、AI 推薦、疲勞度追蹤等功能，顯示應用信息和用戶 UID
import 'package:flutter/material.dart';
import 'package:data_transmit/fatigue/pages/flchart_fristpage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomBottomAppBar extends StatelessWidget {
  const CustomBottomAppBar({
    this.fabLocation = FloatingActionButtonLocation.endDocked,
    this.shape = const CircularNotchedRectangle(),
    this.color = Colors.blue, // 預設顏色
    super.key,
  });

  final FloatingActionButtonLocation fabLocation;
  final NotchedShape? shape;
  final Color color; // 新增

  static final List<FloatingActionButtonLocation> centerLocations = [
    FloatingActionButtonLocation.centerDocked,
    FloatingActionButtonLocation.centerFloat,
  ];

  void _showAppInfoDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '未登入';
    // 作者名單或其他資訊：可依需求修改
    const authors = [
      'Jack Pan',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('相關資料'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UID: $uid'),
              const SizedBox(height: 12),
              const Text('作者名單：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...authors.map((a) => Text('• $a')),
              const SizedBox(height: 12),
              Text('版本：1.0.0'), // 可改為自動抓取版本
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: shape,
      // color: Colors.blue.shade50,        // ✅ 如果有背景色，統一使用系統色
      elevation: 8,
      child: IconTheme(
        data: IconThemeData(color: Colors.black), // 使用傳入顏色的黑色版本
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              tooltip: 'Open navigation menu',
              icon: const Icon(Icons.menu),
              onPressed: () async {
                final RenderBox button = context.findRenderObject() as RenderBox;
                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

                final selected = await showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx,
                    position.dy - 8, // 微調讓選單貼齊 BottomAppBar 上方
                    position.dx + button.size.width,
                    position.dy + button.size.height,
                  ),
                  items: [
                    /*PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('設定'),
                      ),
                    ),*/
                    PopupMenuItem(
                      value: 'info',
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('相關資料'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'chart',
                      child: ListTile(
                        leading: const Icon(Icons.show_chart),
                        title: const Text('疲勞度繪圖'),
                      ),
                    ),
                  ],
                );

                if (!context.mounted) return;

                if (selected == 'settings') {
                  // 處理設定
                } else if (selected == 'info') {
                  _showAppInfoDialog(context);
                } else if (selected == 'chart') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Flchartfristpage(),
                    ),
                  );
                }
              },
            ),
            /*if (centerLocations.contains(fabLocation)) const Spacer(),
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              tooltip: 'Favorite',
              icon: const Icon(Icons.favorite),
              onPressed: () {},
            ),*/
            IconButton(
              icon: Icon(
                Icons.calendar_today,
                color: Colors.blue.shade600, // ✅ 統一圖標顏色
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // 回到首頁
              },
            ),
          ],
        ),
      ),
    );
  }
}
