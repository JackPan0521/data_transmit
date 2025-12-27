//應用程序執行入口點
//負責初始化 Firebase 和身份驗證，然後啟動主應用
// 核心導入
import 'package:flutter/material.dart';
import 'dart:developer' as developer; // 用於控制台日誌輸出

// Firebase 相關導入
import 'package:firebase_core/firebase_core.dart'; // Firebase 核心
import 'package:firebase_auth/firebase_auth.dart'; // Firebase 身份驗證

// 本地導入
import 'core/app.dart'; // 應用主頁面
import 'core/error_handler.dart'; // 錯誤處理頁面
import 'firebase_options.dart'; // Firebase 配置選項

/// 獲取或創建用戶 UID
/// 如果用戶未登入，則進行匿名登入
/// 返回當前用戶的唯一標識符 (UID)
Future<String> getOrCreateUid() async {
  final auth = FirebaseAuth.instance;
  User? user = auth.currentUser; // 獲取當前登入的用戶
  
  if (user == null) {
    // 如果用戶未登入，進行匿名登入
    UserCredential credential = await auth.signInAnonymously();
    user = credential.user;
  }
  
  return user!.uid; // 返回用戶的 UID
}

/// 應用程序入口點
void main() async {
  // 確保 Flutter 綁定已初始化，允許在異步操作前執行
  WidgetsFlutterBinding.ensureInitialized();
  // debugShowCheckedModeBanner 是 MaterialApp 的屬性，不能放在這裡。
  // 如需隱藏右上角的 Debug 標記，請在 MyApp（MaterialApp）中設定。
 
  try {
    // === Firebase 初始化區塊 ===
    developer.log("🚀 開始初始化 Firebase...", name: 'Firebase');
    
    // 根據當前平台初始化 Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log("✅ Firebase 初始化成功！", name: 'Firebase');
 
    // === 用戶身份驗證區塊 ===
    // 獲取或創建匿名用戶的 UID
    final uid = await getOrCreateUid();
    developer.log('目前使用者的 UID：$uid', name: 'FirebaseAuth');
 
    // === 啟動應用程序 ===
    runApp(const MyApp());
    
  } catch (e, stackTrace) {
    // === 錯誤處理區塊 ===
    // 記錄初始化失敗的詳細信息
    developer.log(
      "❌ Firebase 初始化失敗",
      name: 'Firebase',
      error: e,
      stackTrace: stackTrace,
    );
    // 顯示錯誤頁面
    runApp(ErrorHandler(error: e.toString()));
  }
}
