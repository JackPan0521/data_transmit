//應用 UI 主入口
//定義 MaterialApp 配置，包括主題、首頁等全局設定
import 'package:flutter/material.dart';
import '../home_screen/calendar.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      debugShowCheckedModeBanner: false,
      home: const CalendarScreen(),
    );
  }
}