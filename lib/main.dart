import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'components/error_boundary.dart';
import 'config/firebase_config.dart'; // File di configurazione esterno

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(
    ErrorBoundary(
      fallback: (error, stack) => Material(
        child: Center(
          child: Text('Errore critico: ${error.toString()}'),
        ),
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const storage = FlutterSecureStorage();
    
    return MaterialApp(
      title: 'miachat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: MediaQuery.of(context).platformBrightness,
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(storage),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true 
              ? const HomeScreen() 
              : const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/logs': (context) => const LogScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }

  Future<bool> _checkLoginStatus(FlutterSecureStorage storage) async {
    try {
      return await storage.containsKey(key: 'apiKey');
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }
}
