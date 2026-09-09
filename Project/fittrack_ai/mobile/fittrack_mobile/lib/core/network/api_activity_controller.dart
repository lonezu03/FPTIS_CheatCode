import 'package:flutter/foundation.dart';

const duplicateMutationMessage =
    'Thao tác này đang được xử lý. Vui lòng chờ API phản hồi.';

class ApiActivityController extends ChangeNotifier {
  final Map<int, bool> _activeRequests = <int, bool>{};
  int _nextId = 1;
  bool _disposed = false;

  int get pendingRequests => _activeRequests.length;
  int get pendingMutations =>
      _activeRequests.values.where((isMutation) => isMutation).length;
  bool get isBusy => pendingRequests > 0;
  bool get isMutating => pendingMutations > 0;

  VoidCallback begin({required bool isMutation}) {
    final id = _nextId++;
    _activeRequests[id] = isMutation;
    _notifySafely();

    var finished = false;
    return () {
      if (finished) return;
      finished = true;
      _activeRequests.remove(id);
      _notifySafely();
    };
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _activeRequests.clear();
    super.dispose();
  }
}

class ApiMutationGuard {
  final Set<String> _activeKeys = <String>{};

  VoidCallback? acquire(String key) {
    if (!_activeKeys.add(key)) return null;

    var released = false;
    return () {
      if (released) return;
      released = true;
      _activeKeys.remove(key);
    };
  }
}
