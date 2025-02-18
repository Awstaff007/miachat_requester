// #### **lib/home_screen.dart**

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_screen.dart';
import 'help_screen.dart';
import 'package:path_provider/path_provider.dart'; // <-- Aggiunto
import 'dart:io';

// Modificato widget ListTile a componente riutilizzabile
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
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = FlutterSecureStorage();
  final NotificationService _notificationService = NotificationService();
  final _scrollController = ScrollController();

  bool _isPaused = false;
  bool _incrementalBackoff = true;
  int _customInterval = 5;
  int _currentInterval = 1;
  int _maxInterval = 30;
  int _maxRetries = 10;
  int _retryCount = 0;

  String _conversationId = '';
  List<String> _errorMessages = ['The server is busy. Please try again later.'];
  Timer? _timer;
  bool _continueConversation = false;

  String _question = 'La tua domanda qui';

  // Circuit Breaker Pattern
  bool _circuitBreakerActive = false;
  int _failureCount = 0;
  final int _maxFailures = 5;
  Timer? _circuitBreakerTimer; // Timer per il circuit breaker

  bool _darkModeEnabled = false;
  final CircuitBreaker _circuitBreaker = CircuitBreaker(
    maxFailures: 5,
    cooldownDuration: Duration(minutes: 30),
  );

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadDarkModePreference();
    _startRequestCycle();
  }

  Future<void> _loadPreferences() async {
    // ... (unchanged)
  }

  void _savePreferences() async {
    // ... (unchanged)
  }

  Future<void> _loadDarkModePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _darkModeEnabled = prefs.getBool('darkMode') ?? false);
  }

  Future<void> _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _darkModeEnabled = value);
    await prefs.setBool('darkMode', value);
  }

  void _startRequestCycle() {
    _retryCount = 0;
    _currentInterval = _incrementalBackoff ? 1 : _customInterval;
    _timer?.cancel();
    _sendRequest();
  }

  Future<void> _sendRequest() async {
    if (_isPaused || _retryCount >= _maxRetries || _circuitBreaker.isActive) {
      _showErrorDialog('Circuit breaker attivo. Riprova tra ${_circuitBreaker.remainingCooldown}');
      return;
    }

    try {
      // ... codice richiesta esistente ...
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // ... (success handling - unchanged)
        _circuitBreaker.recordSuccess();
        _failureCount = 0; // Reset failure count on success
      } else {
        await _logToFile('Errore API: ${response.body}');
        _circuitBreaker.recordFailure();
        _checkCircuitBreakerStatus();
        _failureCount++; // Increment failure count on error
        _retryCount++;
        _applyBackoff();
      }
    } catch (e) {
      print('Errore di rete: $e');
      await _logToFile('Errore di rete: $e');
      await _notificationService.sendNotification(
        'Errore di Rete',
        'Si è verificato un errore di rete.',
      );
      _circuitBreaker.recordFailure();
      _checkCircuitBreakerStatus();
      _failureCount++; // Increment failure count on network error
      _retryCount++;
      _applyBackoff();
    }
  }

  void _checkCircuitBreakerStatus() {
    if (_circuitBreaker.isActive) {
      _notificationService.sendNotification(
        'Circuit Breaker Attivato',
        'Riprendiamo tra 30 minuti',
        type: 'error',
      );
    }
  }

  void _applyBackoff() {
    // ... (unchanged)
  }

  void _scheduleNextRequest() {
    // ... (unchanged)
  }

  void _pauseRequests() {
    // ... (unchanged)
  }

  void _exitApp() {
    // ... (unchanged)
  }

  void _showErrorDialog(String message) {
    // ... (unchanged)
  }

  Future<void> _logToFile(String message) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/app_log.txt';
    final file = File(path);
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
  }

  void _navigateToLogs() {
    // ... (unchanged)
  }

  void _navigateToHelp() {
    // ... (unchanged)
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circuitBreakerTimer?.cancel(); // Cancel the circuit breaker timer
    _savePreferences();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SettingsSwitchTile( // Componente riutilizzabile
              title: 'Backoff Esponenziale',
              subtitle: 'Incrementa l\'intervallo tra i tentativi dopo ogni errore.',
              value: _incrementalBackoff,
              onChanged: (value) {
                setState(() {
                  _incrementalBackoff = value;
                  _savePreferences();
                });
              },
            ),
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _darkModeEnabled,
              onChanged: _toggleDarkMode,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _errorMessages.length,
              itemBuilder: (context, index) => ErrorMessageItem(
                message: _errorMessages[index],
              ),
            ),
            // ... (rest of the UI - unchanged)
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String message) {
    // ... (unchanged)
  }
}

// Classe Circuit Breaker
class CircuitBreaker {
  final int maxFailures;
  final Duration cooldownDuration;
  int _failureCount = 0;
  DateTime? _cooldownStart;

  CircuitBreaker({required this.maxFailures, required this.cooldownDuration});

  bool get isActive => _failureCount >= maxFailures;

  Duration? get remainingCooldown {
    if (_cooldownStart == null) return null;
    final elapsed = DateTime.now().difference(_cooldownStart!);
    return elapsed < cooldownDuration ? cooldownDuration - elapsed : null;
  }

  void recordFailure() {
    _failureCount++;
    if (isActive) {
      _cooldownStart = DateTime.now();
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _cooldownStart = null;
  }
}

// Widget ottimizzato
class ErrorMessageItem extends StatelessWidget {
  const ErrorMessageItem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(message),
      trailing: const Icon(Icons.delete),
    );
  }
}