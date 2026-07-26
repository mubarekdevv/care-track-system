import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/school_admin_provider.dart';

/// Pick a teacher who registered for this subject, then assign to the grade slot.
Future<void> showAssignTeacherDialog(
  BuildContext context, {
  required String classRoomId,
  required String subjectId,
}) async {
  final admin = context.read<SchoolAdminProvider>();
  final subjectName = admin.subjectNameForId(subjectId) ?? 'Subject';
  final gradeLabel = admin.gradeNameForClassRoom(classRoomId) ?? 'this grade';
  final eligible = admin.teachersEligibleForSubject(subjectId);

  if (admin.teachers.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No teachers linked yet. Ask staff to register as Teacher, then tap '
          '"Link teachers" on the Staff tab.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
    return;
  }

  if (eligible.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No teacher registered to teach $subjectName. '
          'Ask a teacher to sign up and select $subjectName in their profile, '
          'or update an existing teacher\'s subjects.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    return;
  }

  var selectedId = eligible.first.uid;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Assign teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$subjectName · $gradeLabel',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Only teachers who registered to teach $subjectName in $gradeLabel are listed.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                labelText: 'Teacher',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: eligible
                  .map((t) => DropdownMenuItem(value: t.uid, child: Text(t.fullName)))
                  .toList(),
              onChanged: (v) => setState(() => selectedId = v ?? selectedId),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    ),
  );

  if (ok != true || !context.mounted) return;

  final saved = await admin.assignTeacher(
    classRoomId: classRoomId,
    subjectId: subjectId,
    teacherId: selectedId,
  );
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        saved
            ? 'Assigned to $gradeLabel · $subjectName.'
            : admin.error ?? 'Could not assign teacher.',
      ),
      backgroundColor: saved ? AppTheme.softGreen : null,
    ),
  );
}
