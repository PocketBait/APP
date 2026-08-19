import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/friends/data/friends_repository.dart';
import '../../features/limits/data/limits_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../config/supabase_config.dart';

/// Cliente único de Supabase, ya inicializado en `main.dart`. Todos los
/// repositorios dependen de este provider en vez de leer `supabase`
/// (variable global) directamente — así son testeables con un cliente falso.
final supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepository(ref.watch(supabaseClientProvider)),
);

final limitsRepositoryProvider = Provider<LimitsRepository>(
  (ref) => LimitsRepository(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);
