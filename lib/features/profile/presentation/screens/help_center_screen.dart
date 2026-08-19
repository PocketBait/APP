import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class _Faq {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;
}

const _faqs = [
  _Faq(
    '¿Cómo agrego a un amigo?',
    'Ve a la pestaña Amigos → botón "Agregar" → busca su usuario o '
        'nombre → toca "Agregar". Cuando acepte tu solicitud, ya son '
        'amigos.',
  ),
  _Faq(
    '¿Cómo le doy acceso a un amigo para que me proponga límites?',
    'Entra a Límites → pestaña Accesos → "Dar acceso" → elige a un amigo. '
        'Solo puedes dárselo a alguien que ya sea tu amigo.',
  ),
  _Faq(
    '¿Puedo rechazar una propuesta de límite?',
    'Sí, siempre. Ninguna propuesta aplica hasta que tú la aceptas '
        'expresamente — puedes rechazarla sin dar explicación.',
  ),
  _Faq(
    '¿Cómo dejo de ser amigo de alguien?',
    'Entra a su perfil desde la pestaña Amigos, toca el menú "⋮" arriba '
        'a la derecha, y elige "Dejar de ser amigos". Esto también quita '
        'cualquier acceso que se hayan dado el uno al otro.',
  ),
  _Faq(
    '¿Cómo elimino mi cuenta?',
    'Ve a Perfil → Data privacy → "Eliminar mi cuenta". Es permanente: '
        'se borra tu perfil y todo lo relacionado.',
  ),
  _Faq(
    '¿La app ya bloquea las apps de verdad en mi celular?',
    'Todavía no. Por ahora PocketBait es el acuerdo entre amigos (quién '
        'propone, quién acepta, por cuánto tiempo) — el bloqueo real de '
        'apps en el teléfono está en desarrollo.',
  ),
];

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final faq in _faqs)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ExpansionTile(
                title: Text(faq.question),
                childrenPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faq.answer,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.outline)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text('¿Necesitas más ayuda? '
                        'Escríbenos a soporte@pocketbait.com'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
