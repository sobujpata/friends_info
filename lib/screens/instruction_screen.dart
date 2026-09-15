import 'package:flutter/material.dart';

/// A single step shown on the instruction page.
class _Step {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _Step(this.number, this.icon, this.title, this.description);
}

/// How-to-use guide explaining the main app features step by step.
class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  static const _steps = [
    _Step(
      '01',
      Icons.login,
      'Sign in',
      'Sign in with your personnel number and the shared app password. '
          'Each user gets a private list of friends stored on this device.',
    ),
    _Step(
      '02',
      Icons.person_add_alt,
      'Add a friend',
      'Tap the "Add friend" button on the Home tab and fill in the details. '
          'Name, personnel number and phone are required; trade, blood group, '
          'district, upazila and address are optional.',
    ),
    _Step(
      '03',
      Icons.search,
      'Search & favorites',
      'Use the search box to filter by name, personnel number or phone. '
          'Tap the star icon on the app bar to show only your favorites.',
    ),
    _Step(
      '04',
      Icons.contact_phone_outlined,
      'Call & WhatsApp',
      'Open a friend\'s card, then use the Call or WhatsApp button to reach '
          'them instantly, or tap any contact row to see more details.',
    ),
    _Step(
      '05',
      Icons.edit_outlined,
      'Edit or delete',
      'Use the edit and delete icons inside a friend\'s detail page. From the '
          'list you can also swipe a card leftwards to delete it.',
    ),
    _Step(
      '06',
      Icons.backup_outlined,
      'Backup & restore',
      'Tap the three-dot menu in the app bar to export a backup of your '
          'friends or restore an earlier one at any time.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: scheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Follow these steps to get the most out of Friends Info.',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final step in _steps) _StepCard(step: step),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final _Step step;

  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(step.number,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, size: 20, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(step.title,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(step.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
