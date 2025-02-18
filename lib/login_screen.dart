// #### **lib/login_screen.dart**

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';
import 'help_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = FlutterSecureStorage();
  final _apiKeyController = TextEditingController();
  bool _rememberMe = true;

  // Aggiunta regex validazione API Key
  bool _validateApiKey(String key) {
    const pattern = r'^miachat_[A-Za-z0-9]{40}$';
    return RegExp(pattern).hasMatch(key);
  }

  // Modificata funzione _login
  Future<void> _login() async {
    final apiKey = _apiKeyController.text.trim();

    if (!_validateApiKey(apiKey)) { // <-- Validazione aggiunta
      _showErrorDialog('Formato API Key non valido. Esempio: miachat_123...');
      return;
    }

    if (apiKey.isNotEmpty) {
      if (_rememberMe) {
        await _storage.write(key: 'apiKey', value: apiKey);
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showErrorDialog('Per favore, inserisci una API Key valida.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Errore di Login'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HelpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _navigateToHelp,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Inserisci la tua DeepSeek API Key per continuare.',
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'DeepSeek API Key',
                suffixIcon: IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () {
                    _showInfoDialog(
                        'Inserisci la tua DeepSeek API Key. Puoi ottenerla dal tuo account sul sito di DeepSeek.');
                  },
                ),
              ),
            ),
            CheckboxListTile(
              title: Text('Ricorda la API Key'),
              value: _rememberMe,
              onChanged: (newValue) {
                setState(() {
                  _rememberMe = newValue!;
                });
              },
            ),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Informazioni'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}