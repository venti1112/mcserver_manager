import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/rcon_provider.dart';
import 'providers/server_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 预加载服务器列表
  final serverProvider = ServerProvider();
  await serverProvider.loadServers();

  // 预加载主题设置
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: serverProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => RconProvider()),
      ],
      child: const MCServerManagerApp(),
    ),
  );
}
