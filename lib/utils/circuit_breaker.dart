// ***** 1. lib/utils/circuit_breaker.dart *****

import 'dart:async';

class CircuitBreaker {
  final int maxFailures;
  final Duration cooldownDuration;
  int _failureCount = 0;
  bool _isBreakerActive = false;
  Timer? _cooldownTimer;

  CircuitBreaker({
    this.maxFailures = 5,
    this.cooldownDuration = const Duration(minutes=30)
  });

  void recordFailure() {
    _failureCount++;
    if (!_isBreakerActive && _failureCount >= maxFailures) {
      _activateBreaker();
    }
  }

  void recordSuccess() => _failureCount = 0;

  bool get isActive => _isBreakerActive;

  void _activateBreaker() {
    _isBreakerActive = true;
    _cooldownTimer = Timer(cooldownDuration, () {
      _isBreakerActive = false;
      _failureCount = 0;
    });
  }

  void dispose() => _cooldownTimer?.cancel();
}