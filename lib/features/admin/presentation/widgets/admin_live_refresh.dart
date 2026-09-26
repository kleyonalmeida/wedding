import 'dart:async';
import 'package:flutter/material.dart';

/// Refreshes visible financial pages without overlapping background requests.
mixin AdminLiveRefresh<T extends StatefulWidget> on State<T> {
  Timer? _refreshTimer;
  AppLifecycleListener? _lifecycleListener;
  bool _refreshRunning = false;

  Future<void> refreshData();

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) {
          _startRefreshTimer();
          unawaited(_refreshVisiblePage());
        } else {
          _refreshTimer?.cancel();
        }
      },
    );
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshVisiblePage()),
    );
  }

  Future<void> _refreshVisiblePage() async {
    if (!mounted ||
        _refreshRunning ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _refreshRunning = true;
    try {
      await refreshData();
    } finally {
      _refreshRunning = false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
