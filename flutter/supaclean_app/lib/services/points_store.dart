import 'package:flutter/foundation.dart';

import '../models/points.dart';
import 'order_api.dart';

/// The signed-in customer's points, shared by the Home card, the Profile
/// option, the points page and the payment screen.
///
/// It keeps what it last loaded if the server can't be reached, and stays
/// empty when the app has no server set up, so those screens simply hide the
/// points instead of showing an error.
class PointsStore extends ChangeNotifier {
  PointsStore({Future<PointsSummary?> Function()? fetch})
      : _fetch = fetch ?? _fromServer;

  /// The one the screens share.
  static final PointsStore instance = PointsStore();

  final Future<PointsSummary?> Function() _fetch;

  PointsSummary? _summary;

  /// Null until the server has answered.
  PointsSummary? get summary => _summary;

  static Future<PointsSummary?> _fromServer() async {
    final api = OrderApi();
    if (!api.isConfigured) return null;
    return api.myPoints();
  }

  Future<void> refresh() async {
    try {
      final loaded = await _fetch();
      if (loaded == null) return;
      _summary = loaded;
      notifyListeners();
    } catch (_) {
      // Keep showing what we have.
    }
  }

  /// Forgets everything, for when someone signs out.
  void clear() {
    if (_summary == null) return;
    _summary = null;
    notifyListeners();
  }

  /// Sets the points directly, for tests.
  @visibleForTesting
  void setForTest(PointsSummary? summary) {
    _summary = summary;
    notifyListeners();
  }
}
