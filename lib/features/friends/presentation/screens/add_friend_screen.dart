import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
  final Set<String> _sentTo = {};

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
      final userId = ref.read(requireUserIdProvider);
      final results =
          await repository.searchProfiles(query, excludeUserId: userId);
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
              decoration: const InputDecoration(
                hintText: 'Buscar por usuario o nombre',
                prefixIcon: Icon(Icons.search),
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
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final profile = _results[index];
                  final alreadySent = _sentTo.contains(profile.id);
                  return Card(
                    child: ListTile(
                      leading: ProfileAvatar(profile: profile),
                      title: Text(profile.displayName),
                      subtitle: Text('@${profile.username}'),
                      trailing: alreadySent
                          ? const Text('Enviada')
                          : FilledButton(
                              onPressed: actions.isLoading
                                  ? null
                                  : () async {
                                      await ref
                                          .read(friendActionsControllerProvider
                                              .notifier)
                                          .sendRequest(profile.id);
                                      if (mounted) {
                                        setState(
                                            () => _sentTo.add(profile.id));
                                      }
                                    },
                              child: const Text('Agregar'),
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
}
