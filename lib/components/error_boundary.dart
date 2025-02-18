// ***** 3. lib/components/error_boundary.dart *****

import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? fallback;

  const ErrorBoundary({
    required this.child,
    this.fallback,
    Key? key
  }) : super(key: key);

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.fallback != null) {
      return widget.fallback!(_error!, _stackTrace!);
    }
    return widget.child;
  }

  void catchError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (errorDetails) {
      return widget.fallback?.call(
            errorDetails.exception,
            errorDetails.stack ?? StackTrace.empty,
          ) ??
          Center(child: Text('Errore non gestito'));
    };
  }

  static void triggerManualError(
    BuildContext context, 
    Object error, 
    StackTrace stack
  ) {
    context.findAncestorStateOfType<_ErrorBoundaryState>()?.catchError(error, stack);
  }

  static _ErrorBoundaryState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ErrorBoundaryState>();
  }
}
