import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/update_service.dart';
import 'features/server_list/server_list_page.dart';
import 'providers/theme_provider.dart';

/// 全局导航 Key，供启动时的静默更新检查使用。
final navigatorKey = GlobalKey<NavigatorState>();

class MCServerManagerApp extends StatefulWidget {
  const MCServerManagerApp({super.key});
  @override
  State<MCServerManagerApp> createState() => _MCServerManagerAppState();
}

class _MCServerManagerAppState extends State<MCServerManagerApp> {
  @override
  void initState() {
    super.initState();
    _checkUpdateSilently();
  }

  /// 启动时后台静默检查更新：无更新或检查失败时不打扰用户；
  /// 发现新版本才弹出提示框。
  Future<void> _checkUpdateSilently() async {
    // 等待首帧渲染完成，避免弹窗与启动过程竞争。
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final updateInfo =
          await UpdateService.fetchInfo(userAgent: packageInfo.version);
      if (!mounted || updateInfo == null) return;
      final navContext = navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      UpdateService.showUpdateDialog(
        navContext,
        updateInfo,
        packageInfo.version,
        silentOnNoUpdate: true,
      );
    } catch (_) {
      // 静默检查失败不做任何提示，避免打扰用户。
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MCServer Manager',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.flutterThemeMode,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          home: const ServerListPage(),
        );
      },
    );
  }
}