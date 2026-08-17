import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/friend_request.dart';

/// Todas las solicitudes/amistades donde participa el usuario actual.
/// `autoDispose` para no dejar datos viejos en memoria cuando el usuario
/// sale de la pestaña de amigos; se refresca con `ref.invalidate` después
/// de cada acción (enviar, aceptar, rechazar, cancelar).
final friendRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequest>>((ref) async {
  final repository = ref.watch(friendsRepositoryProvider);
  final userId = ref.watch(requireUserIdProvider);
  return repository.fetchMyFriendRequests(userId);
});

/// Solo las amistades ya confirmadas, derivadas de `friendRequestsProvider`.
final acceptedFriendsProvider =
    Provider.autoDispose<AsyncValue<List<FriendRequest>>>((ref) {
  return ref.watch(friendRequestsProvider).whenData(
        (requests) => requests
            .where((r) => r.status == FriendRequestStatus.accepted)
            .toList(),
      );
});

/// Solicitudes que me llegaron y aún no respondo.
final incomingRequestsProvider =
    Provider.autoDispose<AsyncValue<List<FriendRequest>>>((ref) {
  final userId = ref.watch(requireUserIdProvider);
  return ref.watch(friendRequestsProvider).whenData(
        (requests) =>
            requests.where((r) => r.isIncomingFor(userId)).toList(),
      );
});

/// Solicitudes que yo envié y siguen pendientes.
final outgoingRequestsProvider =
    Provider.autoDispose<AsyncValue<List<FriendRequest>>>((ref) {
  final userId = ref.watch(requireUserIdProvider);
  return ref.watch(friendRequestsProvider).whenData(
        (requests) =>
            requests.where((r) => r.isOutgoingFrom(userId)).toList(),
      );
});

/// Acciones que mutan `friend_requests` (enviar, aceptar, rechazar,
/// cancelar). Tras cada una, invalida la lista para refrescar la UI con
/// datos frescos del servidor en vez de mutar el estado local a mano.
class FriendActionsController extends StateNotifier<AsyncValue<void>> {
  FriendActionsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> sendRequest(String addresseeId) => _run(() {
        final repository = _ref.read(friendsRepositoryProvider);
        final userId = _ref.read(requireUserIdProvider);
        return repository.sendFriendRequest(
          requesterId: userId,
          addresseeId: addresseeId,
        );
      });

  Future<void> respond({required String requestId, required bool accept}) =>
      _run(() => _ref
          .read(friendsRepositoryProvider)
          .respondToFriendRequest(requestId: requestId, accept: accept));

  Future<void> cancel(String requestId) => _run(
      () => _ref.read(friendsRepositoryProvider).cancelFriendRequest(requestId));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(action);
    _ref.invalidate(friendRequestsProvider);
  }
}

final friendActionsControllerProvider =
    StateNotifierProvider.autoDispose<FriendActionsController, AsyncValue<void>>(
  (ref) => FriendActionsController(ref),
);
