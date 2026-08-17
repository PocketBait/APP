import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Inicializa el cliente de Supabase (Postgres + Auth + Realtime) una sola
/// vez, al arrancar la app. El resto del código nunca crea su propio
/// cliente — todos usan `supabase` para compartir la misma sesión.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

/// Atajo global al cliente ya inicializado.
SupabaseClient get supabase => Supabase.instance.client;
