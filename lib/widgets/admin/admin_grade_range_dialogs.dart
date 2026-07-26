import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/school_admin_provider.dart';

/// Load grades + set school max grade from starter curriculum.
Future<void> showLoadStarterCurriculumDialog(BuildContext context) async {
  final admin = context.read<SchoolAdminProvider>();
  var from = 1;
  var to = admin.effectiveMaxCatalogGradeLevel > 0
      ? admin.effectiveMaxCatalogGradeLevel
      : 5;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        final toItems = List.generate(12, (i) => i + 1).where((n) => n >= from).toList();
        if (!toItems.contains(to)) to = toItems.last;

        return AlertDialog(
          title: const Text('Load starter curriculum'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Creates standard grades with subject slots and sets the highest grade '
                  'your school can add (e.g. up to Grade 5 hides Grade 6+ in the add menu '
                  'until you extend the range).',
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: from,
                        decoration: const InputDecoration(labelText: 'From grade'),
                        items: List.generate(12, (i) => i + 1)
                            .map((n) => DropdownMenuItem(value: n, child: Text('Grade $n')))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            from = v ?? 1;
                            if (to < from) to = from;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: to,
                        decoration: const InputDecoration(labelText: 'Up to grade (max)'),
                        items: toItems
                            .map((n) => DropdownMenuItem(value: n, child: Text('Grade $n')))
                            .toList(),
                        onChanged: (v) => setState(() => to = v ?? from),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'After load, admins can add grades 1–$to only.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: admin.isBusy ? null : () => Navigator.pop(ctx, true),
              child: const Text('Load'),
            ),
          ],
        );
      },
    ),
  );

  if (result != true || !context.mounted) return;
  if (from > to) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('"From" must be less than or equal to "Up to grade".')),
    );
    return;
  }
  final message = await admin.seedGradesRange(fromLevel: from, toLevel: to);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Raise max grade without seeding (e.g. extend from 5 to 10).
Future<void> showChangeMaxGradeDialog(BuildContext context) async {
  final admin = context.read<SchoolAdminProvider>();
  final floor = admin.highestCatalogLevelAmongGrades > 0
      ? admin.highestCatalogLevelAmongGrades
      : 1;
  var max = admin.effectiveMaxCatalogGradeLevel > 0
      ? admin.effectiveMaxCatalogGradeLevel
      : floor;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Highest grade level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              floor > 1
                  ? 'You already have grades through Grade $floor. Max cannot go lower.'
                  : 'Controls which grades appear in the add-grade dropdown.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: max < floor ? floor : max,
              decoration: const InputDecoration(labelText: 'Up to grade'),
              items: List.generate(12, (i) => i + 1)
                  .where((n) => n >= floor)
                  .map((n) => DropdownMenuItem(value: n, child: Text('Grade $n')))
                  .toList(),
              onChanged: (v) => setState(() => max = v ?? floor),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    ),
  );

  if (result != true || !context.mounted) return;
  final ok = await admin.setMaxCatalogGradeLevel(max);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? 'Highest grade set to Grade $max.'
            : admin.error ?? 'Could not update.',
      ),
    ),
  );
}
