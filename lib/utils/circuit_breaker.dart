// ***** 1. lib/utils/circuit_breaker.dart *****

import 'dart:async';

class CircuitBreaker {
  int _failureCount = 0;
  bool _isActive = false;
  Timer? _cooldownTimer;
  
  static const int _maxFailures = 5;
  static const Duration _cooldown = Duration(minutes: 30);

  bool get isActive => _isActive;

  void recordSuccess() => _failureCount = 0;

  void recordFailure() {
    _failureCount++;
    if (_failureCount >= _maxFailures && !_isActive) {
      _activate();
    }
  }

  void _activate() {
    _isActive = true;
    _cooldownTimer = Timer(_cooldown, _reset);
  }

  void _reset() {
    _isActive = false;
    _failureCount = 0;
    _cooldownTimer?.cancel();
  }

  void dispose() {
    _cooldownTimer?.cancel();
  }
}
