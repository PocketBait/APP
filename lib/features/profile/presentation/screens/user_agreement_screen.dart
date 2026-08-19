import 'package:flutter/material.dart';

import '../widgets/legal_doc_screen.dart';

/// Borrador razonable basado en lo que la app hace hoy (Fase 1, sin
/// dinero). No sustituye la revisión de un abogado antes de publicar la
/// app de verdad.
class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocScreen(
      title: 'Términos y condiciones',
      lastUpdated: '19 de agosto de 2026',
      sections: [
        LegalSection(
          'Qué es PocketBait',
          'PocketBait es una app para que amigos acuerden límites de '
              'tiempo de pantalla entre ellos. Ningún límite aplica sin '
              'que la persona lo acepte de forma explícita.',
        ),
        LegalSection(
          'Requisitos para usar la app',
          'Necesitas tener al menos 13 años y dar información verdadera '
              'al registrarte (nombre, fecha de nacimiento, etc.).',
        ),
        LegalSection(
          'Cómo funcionan los límites',
          'Un límite propuesto por un amigo con acceso solo aplica si tú '
              'lo aceptas expresamente. Puedes rechazar cualquier '
              'propuesta, revocar el acceso que le diste a alguien, o '
              'dejar de ser su amigo, en cualquier momento.',
        ),
        LegalSection(
          'Conducta esperada',
          'No está permitido acosar a otros usuarios, suplantar la '
              'identidad de alguien más, ni usar la app para dañar a otra '
              'persona. Las cuentas que incumplan esto pueden ser '
              'suspendidas o eliminadas.',
        ),
        LegalSection(
          'Sin garantías',
          'La app se ofrece "tal cual". Hacemos nuestro mejor esfuerzo '
              'para que funcione bien, pero no garantizamos que esté '
              'libre de errores en todo momento.',
        ),
        LegalSection(
          'Cambios al servicio',
          'Podemos agregar, modificar o discontinuar funciones. Futuras '
              'funciones que involucren dinero (como apuestas entre '
              'amigos) van a tener sus propios términos y van a cumplir '
              'la regulación que les aplique.',
        ),
        LegalSection(
          'Ley aplicable',
          'Estos términos se rigen por las leyes de México.',
        ),
        LegalSection(
          'Contacto',
          'Si tienes dudas sobre estos términos, escríbenos a '
              'soporte@pocketbait.com.',
        ),
      ],
    );
  }
}
