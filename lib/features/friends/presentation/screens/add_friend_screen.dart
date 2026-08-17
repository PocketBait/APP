import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/friend_request.dart';
import '../../domain/profile.dart';
import '../providers/friends_providers.dart';
import '../widgets/profile_avatar.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Profile> _results = const [];
  bool _isSearching = false;
  String? _error;
  // Overlay optimista: mientras `friendRequestsProvider` no haya vuelto a
  // cargar tras enviar una solicitud, esto evita que el botón "Agregar"
  // parpadee de vuelta por una fracción de segundo.
  final Set<String> _optimisticallySent = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final repository = ref.read(friendsRepositoryProvider);
      final results = await repository.searchProfiles(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppException.from(error).message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(friendActionsControllerProvider);
    final userId = ref.watch(requireUserIdProvider);
    final myRequests = ref
        .watch(friendRequestsProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <FriendRequest>[]);

    ref.listen(friendActionsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar amigo')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por usuario o nombre',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isSearching) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: ErrorView(message: _error!),
              ),
            Expanded(
              child: _results.isEmpty && !_isSearching && _controller.text.length >= 2
                  ? const EmptyStateView(
                      icon: Icons.search_off,
                      title: 'No encontramos a nadie con ese nombre',
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final profile = _results[index];
                        final relationship = relationshipWith(
                          myId: userId,
                          otherId: profile.id,
                          myRequests: myRequests,
                        );
                        final alreadySentOptimistically =
                            _optimisticallySent.contains(profile.id);

                        return Card(
                          child: ListTile(
                            leading: ProfileAvatar(profile: profile),
                            title: Text(profile.displayName),
                            subtitle: Text(
                              profile.mutualFriendsCount > 0
                                  ? '@${profile.username} · ${profile.mutualFriendsCount} '
                                      '${profile.mutualFriendsCount == 1 ? "amigo en común" : "amigos en común"}'
                                  : '@${profile.username}',
                            ),
                            trailing: _trailingFor(
                              relationship: relationship,
                              alreadySentOptimistically: alreadySentOptimistically,
                              isLoading: actions.isLoading,
                              onAdd: () async {
                                setState(
                                    () => _optimisticallySent.add(profile.id));
                                await ref
                                    .read(friendActionsControllerProvider.notifier)
                                    .sendRequest(profile.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trailingFor({
    required FriendRelationship relationship,
    required bool alreadySentOptimistically,
    required bool isLoading,
    required VoidCallback onAdd,
  }) {
    if (relationship == FriendRelationship.friends) {
      return const Chip(label: Text('Ya son amigos'));
    }
    if (relationship == FriendRelationship.requestSentByMe ||
        alreadySentOptimistically) {
      return const Chip(label: Text('Solicitud enviada'));
    }
    if (relationship == FriendRelationship.requestReceivedFromThem) {
      return const Chip(label: Text('Te escribió a ti'));
    }
    return FilledButton(
      onPressed: isLoading ? null : onAdd,
      child: const Text('Agregar'),
    );
  }
}
