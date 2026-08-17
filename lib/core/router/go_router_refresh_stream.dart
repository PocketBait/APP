import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta un Stream (el de cambios de sesión de Supabase) a un
/// `Listenable`, que es lo que `GoRouter.refreshListenable` espera para
/// volver a evaluar el `redirect` cada vez que la sesión cambia.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
