import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps [Connectivity] and exposes a simple online/offline boolean stream,
/// collapsing connectivity_plus's list-of-results API into one flag the
/// rest of the app can react to.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_isOnline(results));
    });
  }

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _lastKnown = true;

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Stream of online/offline transitions.
  Stream<bool> get onStatusChange => _controller.stream.map((online) {
    _lastKnown = online;
    return online;
  });

  /// Best-known current status, synchronous. Call [refresh] at startup to
  /// prime it before relying on this.
  bool get isOnline => _lastKnown;

  Future<bool> refresh() async {
    final results = await _connectivity.checkConnectivity();
    final online = _isOnline(results);
    _lastKnown = online;
    _controller.add(online);
    return online;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
