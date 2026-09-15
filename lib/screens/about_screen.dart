import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// ✏️  OWNER INFO — edit these constants to match the actual
//     app owner. Empty/null values are hidden automatically.
// ─────────────────────────────────────────────────────────────
const String kOwnerName = 'MD SALIM REZA';
const String kOwnerPersonnelNo = '01739871705';
const String? kOwnerTrade = null; // e.g. 'Electrical / Mechanical'
const String? kOwnerBloodGroup = null; // e.g. 'O+'
const String? kOwnerDistrict = null; // e.g. 'Dhaka'
const String? kOwnerUpazila = null; // e.g. 'Savar'
const String? kOwnerPhone = null; // e.g. '01700-000000'
const String? kOwnerEmail = null; // e.g. 'owner@example.com'
const String? kOwnerAddress = null; // e.g. 'Savar Cantonment, Dhaka'

const String kAppVersion = '1.0.0';
// ─────────────────────────────────────────────────────────────

/// About screen showing the app and its owner.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    kOwnerName.isNotEmpty ? kOwnerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Friends Info',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Version $kAppVersion',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Text(
                  'A private contact directory to store and manage your '
                  'friends\' information — names, personnel numbers, contacts '
                  'and more — safely on your own device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Owner card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About the owner', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('App developer & data owner',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                const _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Name',
                    value: kOwnerName),
                if (kOwnerPersonnelNo.isNotEmpty)
                  const _InfoRow(
                      icon: Icons.numbers,
                      label: 'Phone No',
                      value: kOwnerPersonnelNo),
                if (_nonEmpty(kOwnerTrade))
                  _InfoRow(
                      icon: Icons.work_outlined,
                      label: 'Trade',
                      value: kOwnerTrade!),
                if (_nonEmpty(kOwnerBloodGroup))
                  _InfoRow(
                      icon: Icons.bloodtype,
                      label: 'Blood group',
                      value: kOwnerBloodGroup!),
                if (_nonEmpty(kOwnerDistrict))
                  _InfoRow(
                      icon: Icons.location_city,
                      label: 'District',
                      value: kOwnerDistrict!),
                if (_nonEmpty(kOwnerUpazila))
                  _InfoRow(
                      icon: Icons.map_outlined,
                      label: 'Upazila',
                      value: kOwnerUpazila!),
                if (_nonEmpty(kOwnerAddress))
                  _InfoRow(
                      icon: Icons.home_outlined,
                      label: 'Present address',
                      value: kOwnerAddress!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Contact card
        if (_nonEmpty(kOwnerPhone) || _nonEmpty(kOwnerEmail))
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_nonEmpty(kOwnerPhone))
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: kOwnerPhone!),
                  if (_nonEmpty(kOwnerEmail))
                    _InfoRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: kOwnerEmail!),
                ],
              ),
            ),
          ),
        // Footer note
        Center(
          child: Text(
            'Made with ❤️ for the team',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  static bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
