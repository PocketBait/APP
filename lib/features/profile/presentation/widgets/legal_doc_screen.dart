import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// Pantalla genérica para mostrar un documento largo por secciones
/// (política de privacidad, términos, etc.) sin necesitar un paquete de
/// markdown para algo tan simple.
class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Última actualización: $lastUpdated',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final section in sections) ...[
            Text(
              section.heading,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(section.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
