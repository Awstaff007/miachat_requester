// #### **lib/login_screen.dart**

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';
import 'help_screen.dart';
import 'utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _storage = FlutterSecureStorage();  // Spostato qui
  bool _rememberMe = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final apiKey = _apiKeyController.text.trim();
      if (_rememberMe) {
        await _storage.write(key: 'apiKey', value: apiKey);
      }
      Navigator.pushReplacementNamed(context, '/home');
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Inserisci la tua DeepSeek API Key per continuare.',
                style: TextStyle(fontSize: 16),
              ),
              TextFormField(
                controller: _apiKeyController,
                validator: MiaChatValidators.apiKeyValidator,
                decoration: const InputDecoration(
                  labelText: 'DeepSeek API Key',
                  hintText: 'miachat_prod_123e4567-...',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () {
                      _showInfoDialog('Inserisci la tua DeepSeek API Key. Puoi ottenerla dal tuo account sul sito di DeepSeek.'); // Modificato
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
