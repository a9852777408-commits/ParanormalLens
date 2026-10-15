import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum PrankState { idle, armed, triggered }

/// Stealth prank engine:
/// Timer-based countdown or sudden shake trigger culminating in an instant jumpscare.
class PrankEngine extends ChangeNotifier {
  static final PrankEngine _instance = PrankEngine._internal();
  factory PrankEngine() => _instance;
  PrankEngine._internal();

  PrankState _state = PrankState.idle;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  StreamSubscription? _shakeSubscription;

  PrankState get state => _state;
  int get remainingSeconds => _remainingSeconds;

  /// Arms the stealth timer with one of [10, 20, 30] seconds
  void armPrank(int seconds) {
    _state = PrankState.armed;
    _remainingSeconds = seconds;

    // Trigger A: Accelerometer violent shake trigger
    _shakeSubscription?.cancel();
    _shakeSubscription = userAccelerometerEvents.listen((event) {
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > 3.2) { // Violent jerk / shake detected
        triggerJumpscare();
      }
    });

    // Trigger B: Timer countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        triggerJumpscare();
      }
      notifyListeners();
    });

    notifyListeners();
    debugPrint('[Prank] Armed for $seconds seconds.');
  }

  void triggerJumpscare() {
    _countdownTimer?.cancel();
    _shakeSubscription?.cancel();

    _state = PrankState.triggered;
    notifyListeners();

    // Max haptic feedback burst
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 250), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 500), () => HapticFeedback.heavyImpact());

    debugPrint('[Prank] JUMPSCARE TRIGGERED!');

    // Auto reset after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      _state = PrankState.idle;
      notifyListeners();
    });
  }

  void cancel() {
    _countdownTimer?.cancel();
    _shakeSubscription?.cancel();
    _state = PrankState.idle;
    notifyListeners();
  }
}
