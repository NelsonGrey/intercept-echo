import 'dart:async';

import 'entitlement_service.dart';

/// Deterministic in-memory [EntitlementService] for tests: no store calls,
/// [purchaseAdRemoval] grants the entitlement immediately.
class FakeEntitlementService implements EntitlementService {
  final _controller = StreamController<bool>.broadcast();
  bool _adFree = false;

  @override
  Future<void> restore() async {}

  @override
  Stream<bool> get adFreeChanges => _controller.stream;

  @override
  bool get isAdFree => _adFree;

  @override
  Future<void> purchaseAdRemoval() async {
    _adFree = true;
    _controller.add(true);
  }
}
