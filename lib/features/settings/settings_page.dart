import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentVersion = '';
  bool _checkingUpdate = false;

  /// 更新信息获取地址
  static const _updateInfoUrl = 'https://icc.gt.tc/MCServerTeam/update.json';

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
      final info = await _fetchUpdateInfo();
      if (!mounted) return;
      setState(() => _checkingUpdate = false);

      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取更新信息失败')),
        );
        return;
      }

      final hasUpdate = info.latestVersion != _currentVersion;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(hasUpdate ? '发现新版本' : '已是最新'),
          content: Text(hasUpdate
              ? '最新版本: ${info.latestVersion}\n当前版本: $_currentVersion'
              : '当前版本 $_currentVersion 已是最新'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
            if (hasUpdate)
              FilledButton(
                onPressed: () => _openDownloadLink(info.downloadLink),
                child: const Text('立即更新'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkingUpdate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查更新失败：$e')),
      );
    }
  }

  Future<_UpdateInfo?> _fetchUpdateInfo() async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse(_updateInfoUrl))
          .timeout(const Duration(seconds: 8));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'MCServerManager/$_currentVersion',
      );
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return _UpdateInfo(
        latestVersion: json['latestVersion'] as String? ?? '',
        downloadLink: json['downloadLink'] as String? ?? '',
      );
    } finally {
      client.close();
    }
  }

  Future<void> _openDownloadLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载链接无效')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开下载链接')),
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

/// 更新信息，对应 JSON：{"latestVersion":"1.3.0","downloadLink":"https://..."}
class _UpdateInfo {
  final String latestVersion;
  final String downloadLink;
  _UpdateInfo({required this.latestVersion, required this.downloadLink});
}
