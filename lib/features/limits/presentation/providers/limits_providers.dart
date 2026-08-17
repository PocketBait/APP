import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/limit_proposal.dart';
import '../../domain/limit_proposal_app.dart';
import '../../domain/permission_grant.dart';

// ---------------------------------------------------------------------
// Accesos otorgados (permission_grants)
// ---------------------------------------------------------------------

final myGrantsProvider =
    FutureProvider.autoDispose<List<PermissionGrant>>((ref) async {
  final repository = ref.watch(limitsRepositoryProvider);
  final userId = ref.watch(requireUserIdProvider);
  return repository.fetchMyGrants(userId);
});

/// Accesos que YO le di a un amigo para que me proponga límites a mí.
final grantsIGaveProvider =
    Provider.autoDispose<AsyncValue<List<PermissionGrant>>>((ref) {
  final userId = ref.watch(requireUserIdProvider);
  return ref
      .watch(myGrantsProvider)
      .whenData((grants) => grants.where((g) => g.isOwnedBy(userId)).toList());
});

/// Accesos que un amigo me dio a MÍ para poder proponerle límites.
final grantsIReceivedProvider =
    Provider.autoDispose<AsyncValue<List<PermissionGrant>>>((ref) {
  final userId = ref.watch(requireUserIdProvider);
  return ref.watch(myGrantsProvider).whenData(
      (grants) => grants.where((g) => !g.isOwnedBy(userId)).toList());
});

class GrantActionsController extends StateNotifier<AsyncValue<void>> {
  GrantActionsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> grantAccess(String trusteeId) => _run(() {
        final repository = _ref.read(limitsRepositoryProvider);
        final userId = _ref.read(requireUserIdProvider);
        return repository.grantAccess(ownerId: userId, trusteeId: trusteeId);
      });

  Future<void> revoke(String grantId) => _run(
      () => _ref.read(limitsRepositoryProvider).revokeGrant(grantId));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(action);
    _ref.invalidate(myGrantsProvider);
  }
}

final grantActionsControllerProvider =
    StateNotifierProvider.autoDispose<GrantActionsController, AsyncValue<void>>(
  (ref) => GrantActionsController(ref),
);

// ---------------------------------------------------------------------
// Propuestas de límite (limit_proposals)
// ---------------------------------------------------------------------

final myProposalsProvider =
    FutureProvider.autoDispose<List<LimitProposal>>((ref) async {
  final repository = ref.watch(limitsRepositoryProvider);
  final userId = ref.watch(requireUserIdProvider);
  return repository.fetchMyProposals(userId);
});

/// Propuestas que me hicieron y todavía tengo que aceptar o rechazar.
final proposalsAwaitingMyResponseProvider =
    Provider.autoDispose<AsyncValue<List<LimitProposal>>>((ref) {
  final userId = ref.watch(requireUserIdProvider);
  return ref.watch(myProposalsProvider).whenData((proposals) =>
      proposals.where((p) => p.isAwaitingResponseFrom(userId)).toList());
});

/// Límites vigentes aplicados sobre mí (ya acepté y no han vencido).
final activeLimitsOnMeProvider =
    Provider.autoDispose<AsyncValue<List<LimitProposal>>>((ref) {
  final userId = ref.watch(requireUserIdProvider);
  return ref.watch(myProposalsProvider).whenData((proposals) => proposals
      .where((p) => p.ownerId == userId && p.isActive)
      .toList());
});

/// Propuestas que yo le hice a un amigo (para hacerles seguimiento).
final proposalsIMadeProvider =
    Provider.autoDispose<AsyncValue<List<LimitProposal>>>((ref) {
  final userId = ref.watch(requireUserIdProvider);
  return ref
      .watch(myProposalsProvider)
      .whenData((proposals) => proposals.where((p) => p.proposedBy == userId).toList());
});

class ProposalActionsController extends StateNotifier<AsyncValue<void>> {
  ProposalActionsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> createProposal({
    required String permissionGrantId,
    required String ownerId,
    required DateTime endsAt,
    DateTime? startsAt,
    String? note,
    required List<LimitProposalApp> apps,
  }) =>
      _run(() {
        final repository = _ref.read(limitsRepositoryProvider);
        final userId = _ref.read(requireUserIdProvider);
        return repository.createProposal(
          permissionGrantId: permissionGrantId,
          ownerId: ownerId,
          proposedBy: userId,
          endsAt: endsAt,
          startsAt: startsAt,
          note: note,
          apps: apps,
        );
      });

  Future<void> respond({required String proposalId, required bool accept}) =>
      _run(() => _ref
          .read(limitsRepositoryProvider)
          .respondToProposal(proposalId: proposalId, accept: accept));

  Future<void> cancel(String proposalId) => _run(
      () => _ref.read(limitsRepositoryProvider).cancelProposal(proposalId));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(action);
    _ref.invalidate(myProposalsProvider);
  }
}

final proposalActionsControllerProvider = StateNotifierProvider.autoDispose<
    ProposalActionsController, AsyncValue<void>>(
  (ref) => ProposalActionsController(ref),
);
