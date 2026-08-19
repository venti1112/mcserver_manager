import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/update_service.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentVersion = '';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _currentVersion = info.version);
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final updateInfo = await UpdateService.fetchInfo(userAgent: _currentVersion);
      if (!mounted) return;
      setState(() => _checkingUpdate = false);

      if (updateInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取更新信息失败')),
        );
        return;
      }

      UpdateService.showUpdateDialog(context, updateInfo, _currentVersion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkingUpdate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查更新失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('外观主题'),
            trailing: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(value: AppThemeMode.light, icon: Icon(Icons.light_mode, size: 18)),
                ButtonSegment(value: AppThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18)),
                ButtonSegment(value: AppThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18)),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (v) => themeProvider.setThemeMode(v.first),
              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('检查更新'),
            subtitle: Text('当前版本: $_currentVersion'),
            trailing: _checkingUpdate
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _checkingUpdate ? null : _checkUpdate,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('开发者：Z有3笔，协作者：venti1112'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('开源许可'),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }
}