import 'package:flutter/material.dart';

import '../widgets/legal_doc_screen.dart';

/// Borrador razonable basado en lo que la app hace hoy (Fase 1, sin
/// dinero). No sustituye la revisión de un abogado antes de publicar la
/// app de verdad — sobre todo antes de activar cualquier función de
/// dinero/apuestas más adelante.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocScreen(
      title: 'Política de privacidad',
      lastUpdated: '19 de agosto de 2026',
      sections: [
        LegalSection(
          '¿Qué datos recolectamos?',
          'Tu nombre completo, nombre de usuario, correo electrónico, '
              'número de celular y fecha de nacimiento cuando creas tu '
              'cuenta. También guardamos los datos que generas al usar la '
              'app: tus amistades, los accesos que das o recibes, y las '
              'propuestas de límites que haces o te hacen.',
        ),
        LegalSection(
          '¿Para qué usamos tus datos?',
          'Para crear y operar tu cuenta, verificar tu identidad al '
              'iniciar sesión, permitir que tus amigos te encuentren por '
              'tu usuario, y confirmar que cumples la edad mínima '
              'necesaria para usar ciertas funciones.',
        ),
        LegalSection(
          '¿Con quién compartimos tus datos?',
          'Con Supabase, nuestro proveedor de base de datos e '
              'infraestructura, y con Google o Apple únicamente si eliges '
              'iniciar sesión con esas opciones. No vendemos ni '
              'compartimos tus datos con terceros con fines '
              'publicitarios.',
        ),
        LegalSection(
          'Tus derechos sobre tus datos',
          'Conforme a la Ley Federal de Protección de Datos Personales en '
              'Posesión de los Particulares, puedes acceder, corregir o '
              'eliminar tus datos personales en cualquier momento desde '
              'Configuración → Account preferences y Data privacy, o '
              'escribiéndonos a privacidad@pocketbait.com.',
        ),
        LegalSection(
          'Menores de edad',
          'Para usar PocketBait necesitas tener al menos 13 años. '
              'Funciones futuras (como las apuestas entre amigos) van a '
              'requerir que tengas 18 años o más, y se anunciarán con '
              'anticipación.',
        ),
        LegalSection(
          'Cambios a esta política',
          'Podemos actualizar este documento conforme la app crezca. Si '
              'hacemos un cambio importante, te lo vamos a avisar dentro '
              'de la app.',
        ),
        LegalSection(
          'Contacto',
          'Si tienes dudas sobre tus datos, escríbenos a '
              'privacidad@pocketbait.com.',
        ),
      ],
    );
  }
}
