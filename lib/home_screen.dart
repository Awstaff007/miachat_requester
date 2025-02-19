// #### **lib/home_screen.dart**

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'utils/circuit_breaker.dart';
import 'notification_service.dart';
import 'log_screen.dart';
import 'help_screen.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CircuitBreaker _circuitBreaker = CircuitBreaker();
  final _storage = const FlutterSecureStorage();
  final _scrollController = ScrollController();
  final _questionController = TextEditingController();
  final _conversationIdController = TextEditingController();
  
  Timer? _requestTimer;
  bool _isPaused = false;
  bool _continueConversation = false;
  String _currentStatus = 'In attesa di iniziare...';
  
  int _retryCount = 0;
  final int _maxRetries = 10;
  bool _incrementalBackoff = true;
  int _currentInterval = 1;
  final int _maxInterval = 30;
  final int _customInterval = 5;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _startRequestCycle();
    NotificationService.notifications.listen(_handleNotification);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _questionController.text = prefs.getString('question') ?? '';
      _conversationIdController.text = prefs.getString('conversationId') ?? '';
      _continueConversation = prefs.getBool('continueConversation') ?? false;
      _incrementalBackoff = prefs.getBool('incrementalBackoff') ?? true;
    });
  }

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('incrementalBackoff', _incrementalBackoff);
  }

  void _startRequestCycle() {
    _retryCount = 0;
    _currentInterval = _incrementalBackoff ? 1 : _customInterval;
    _requestTimer?.cancel();
    _sendRequest();
  }

  Future<void> _sendRequest() async {
    if (_isPaused || _circuitBreaker.isActive) return;

    try {
      final response = await http.post(
        Uri.parse('https://api.miachat.com/chat/completions'),
        headers: await _getHeaders(),
        body: jsonEncode(_buildRequestBody()),
      );

      if (response.statusCode == 200) {
        _handleSuccess(response.body);
      } else {
        _handleError(response.statusCode, response.body);
        _applyBackoff();
      }
    } catch (e) {
      _handleNetworkError(e);
      _applyBackoff();
    }
  }

  void _applyBackoff() {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    _currentInterval = _incrementalBackoff
        ? (_currentInterval < _maxInterval ? _currentInterval * 2 : _maxInterval)
        : _customInterval;
    _requestTimer = Timer(Duration(minutes: _currentInterval), _sendRequest);
  }

  void _logToFile(String message) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/app_log.txt';
    final file = File(path);
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
  }

  // ... metodi rimanenti invariati ...

  @override
  void dispose() {
    _requestTimer?.cancel();
    _circuitBreaker.dispose();
    _questionController.dispose();
    _conversationIdController.dispose();
    super.dispose();
  }
}
