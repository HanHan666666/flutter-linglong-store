import 'dart:async';

/// 防抖工具
class Debounce {
  Debounce(this.duration);

  final Duration duration;
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// 节流工具
class Throttle {
  Throttle(this.duration);

  final Duration duration;
  Timer? _timer;
  bool _isReady = true;

  void call(VoidCallback action) {
    if (!_isReady) return;

    _isReady = false;
    action();

    _timer = Timer(duration, () {
      _isReady = true;
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

typedef VoidCallback = void Function();