import 'package:flutter/foundation.dart';
import '../core/utils/rcon_client.dart';
import 'server_provider.dart';

/// 全局 RCON 连接管理器：为每个服务器维护一个复用的 RconClient，
/// 持续连接复用，避免轮询时反复建立/断开连接。
class RconProvider extends ChangeNotifier {
  final Map<String, RconClient> _clients = {};

  /// 获取某服务器的 RconClient，复用已有连接；未连接则连接。
  /// 连接失败时抛出异常，由调用方决定如何提示。
  Future<RconClient> getClient(ServerConfig server) async {
    var client = _clients[server.id];
    if (client == null) {
      client = RconClient();
      _clients[server.id] = client;
    }
    if (!client.isConnected) {
      await client.connect(server.host, server.port, server.password);
    }
    return client;
  }

  /// 返回某服务器的客户端对象；不存在时返回 null。
  RconClient? clientFor(String id) => _clients[id];

  /// 某服务器是否已建立连接。
  bool isConnected(String id) => _clients[id]?.isConnected ?? false;

  /// 复用连接查询服务器状态。
  Future<ServerStatus> checkStatus(ServerConfig server) async {
    final stopwatch = Stopwatch()..start();
    try {
      final client = await getClient(server);
      final playerInfo = await client.executeCommand('list');
      stopwatch.stop();
      // 执行超时返回 null，视为服务器不可达
      if (playerInfo == null) {
        return ServerStatus(online: false, latencyMs: stopwatch.elapsedMilliseconds);
      }
      return ServerStatus(
        online: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        playerInfo: playerInfo,
      );
    } catch (_) {
      stopwatch.stop();
      return ServerStatus(online: false, latencyMs: stopwatch.elapsedMilliseconds);
    }
  }

  /// 断开并移除某服务器的连接。
  void disposeServer(String id) {
    _clients.remove(id)?.disconnect();
  }

  @override
  void dispose() {
    for (final client in _clients.values) {
      client.disconnect();
    }
    _clients.clear();
    super.dispose();
  }
}

/// 服务器状态快照。
class ServerStatus {
  final bool online;
  final int latencyMs;
  final String? playerInfo;
  ServerStatus({required this.online, this.latencyMs = 0, this.playerInfo});

  /// 从 `list` 返回中解析在线玩家数量。
  /// 如「当前共有0名玩家在线（最大玩家数为20）：」或「There are 0 of a max of 20 players online:」，
  /// 在线人数即提示词中的第一个数字。
  int get playerCount => _parseOnlineCount(playerInfo);
}

int _parseOnlineCount(String? info) {
  if (info == null) return 0;
  final match = RegExp(r'\d+').firstMatch(info);
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}