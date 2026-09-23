import 'dart:async';

typedef RefreshSession = Future<bool> Function();
typedef ClearSession = Future<void> Function();
typedef SessionInvalidated = void Function();

final class SessionAccess {
  String? _accessToken;
  RefreshSession? _refreshSession;
  ClearSession? _clearSession;
  Future<bool>? _refreshing;
  SessionInvalidated? _onInvalidated;

  String? get accessToken => _accessToken;

  void configure({
    required RefreshSession refreshSession,
    required ClearSession clearSession,
  }) {
    _refreshSession = refreshSession;
    _clearSession = clearSession;
  }

  void setAccessToken(String? token) => _accessToken = token;

  void onInvalidated(SessionInvalidated listener) => _onInvalidated = listener;

  Future<bool> refreshOnce() {
    final active = _refreshing;
    if (active != null) return active;
    final action = _refreshSession;
    if (action == null) return Future<bool>.value(false);
    final future = action();
    _refreshing = future;
    return future.whenComplete(() => _refreshing = null);
  }

  Future<void> clear() async {
    _accessToken = null;
    await _clearSession?.call();
    _onInvalidated?.call();
  }
}
