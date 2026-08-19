import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/rcon_client.dart';
import '../player_management/player_list_page.dart';

class ConsolePage extends StatefulWidget {
  final RconClient rconClient;
  const ConsolePage({super.key, required this.rconClient});

  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _history = <String>[];
  int _historyIndex = -1;
  final _outputLines = <_LogLine>[];

  static const _commands = [
    'help', 'list', 'stop', 'say', 'op', 'deop', 'kick', 'ban', 'pardon',
    'gamemode', 'tp', 'give', 'time set', 'weather', 'difficulty',
  ];

  @override
  void initState() {
    super.initState();
    widget.rconClient.onDisconnected = () {
      if (mounted) {
        setState(() => _outputLines.add(_LogLine(text: '[警告] 连接断开，正在重连...', isError: true)));
      }
    };
    widget.rconClient.onReconnected = () {
      if (mounted) {
        setState(() => _outputLines.add(_LogLine(text: '[信息] 重连成功', isCommand: false)));
      }
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeCommand() async {
    final cmd = _controller.text.trim();
    if (cmd.isEmpty) return;

    if (_history.isEmpty || _history.last != cmd) _history.add(cmd);
    _historyIndex = _history.length;

    setState(() {
      _outputLines.add(_LogLine(text: '> $cmd', isCommand: true));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await widget.rconClient.executeCommand(cmd);
      setState(() {
        _outputLines.add(_LogLine(
          text: stripMinecraftCodes(response ?? '(无响应)'),
          isCommand: false,
        ));
      });
    } catch (e) {
      setState(() {
        _outputLines.add(_LogLine(text: '[错误] $e', isCommand: false, isError: true));
      });
    }
    _scrollToBottom();
  }

  void _onTabPressed() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final matches = _commands.where((c) => c.startsWith(input)).toList();
    if (matches.length == 1) {
      _controller.text = matches.first;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: matches.first.length));
    } else if (matches.length > 1) {
      setState(() {
        _outputLines.add(_LogLine(text: '建议：${matches.join(", ")}', isCommand: false));
      });
      _scrollToBottom();
    }
  }

  void _onHistoryNavigate(bool up) {
    if (_history.isEmpty) return;
    setState(() {
      if (up) {
        _historyIndex = (_historyIndex - 1).clamp(0, _history.length - 1);
      } else {
        _historyIndex = (_historyIndex + 1).clamp(0, _history.length);
      }
      _controller.text = _historyIndex < _history.length ? _history[_historyIndex] : '';
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务器控制台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: '玩家管理',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlayerListPage(rconClient: widget.rconClient)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _outputLines.length,
                itemBuilder: (_, i) {
                  final line = _outputLines[i];
                  return SelectableText(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: line.isError
                          ? theme.colorScheme.error
                          : line.isCommand
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) _onHistoryNavigate(true);
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) _onHistoryNavigate(false);
                          if (event.logicalKey == LogicalKeyboardKey.tab) _onTabPressed();
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: '输入命令...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        onSubmitted: (_) => _executeCommand(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _executeCommand,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('发送'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogLine {
  final String text;
  final bool isCommand;
  final bool isError;
  _LogLine({required this.text, this.isCommand = false, this.isError = false});
}