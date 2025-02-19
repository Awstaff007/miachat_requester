// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'log_screen.dart';
import 'notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'components/error_boundary.dart'; // Aggiunto

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSy...',
        appId: '1:123...',
        messagingSenderId: '123...',
        projectId: 'miachat-...',
      ),
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  await NotificationService().init(); // Inizializzazione NotificationService

  // Error boundary globale
  FlutterError.onError = (details) {
    ErrorBoundary.of(details.context as BuildContext)?.catchError(
      details.exception,
      details.stack ?? StackTrace.empty,
    );
  };

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
  final storage = FlutterSecureStorage();

  Future<bool> _checkLogin() async {
    String? apiKey = await storage.read(key: 'apiKey');
    return apiKey != null;
  }

  @override
  Widget build(BuildContext context) {
    final bool _isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return MaterialApp(
      title: 'DeepSeek App',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: FutureBuilder<bool>(
        future: _checkLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/logs': (context) => LogScreen(),
        '/help': (context) => HelpScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return SlideRightRoute(page: HomeScreen());
          case '/logs':
            return FadeRoute(page: LogScreen());
          default:
            return MaterialPageRoute(builder: (_) => LoginScreen());
        }
      },
    );
  }
}

// Error boundary class
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stack) fallback;

  ErrorBoundary({required this.child, required this.fallback});

  static _ErrorBoundaryState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ErrorBoundaryState>();
  }

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  void catchError(Object error, StackTrace stack) {
    setState(() {
      _error = error;
      _stack = stack;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback(_error!, _stack!);
    }
    return widget.child;
  }
}

// Definizione delle animazioni personalizzate
class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}
