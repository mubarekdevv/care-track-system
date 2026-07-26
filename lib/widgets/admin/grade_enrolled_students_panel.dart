import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/firestore/firestore_student_repository.dart';
import '../../models/student_model.dart';

/// Admin: live list of students enrolled in a grade's primary class.
class GradeEnrolledStudentsPanel extends StatelessWidget {
  final String classRoomId;
  final String gradeName;

  const GradeEnrolledStudentsPanel({
    super.key,
    required this.classRoomId,
    required this.gradeName,
  });

  @override
  Widget build(BuildContext context) {
    final repo = FirestoreStudentRepository();

    return StreamBuilder<List<StudentModel>>(
      stream: repo.watchStudentsForClass(classRoomId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final students = snap.data ?? [];
        if (students.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'No students enrolled in $gradeName yet.',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          );
        }

        students.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Enrolled students (${students.length})',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            ...students.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      child: Text(
                        s.fullName.isNotEmpty
                            ? s.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if ((s.displayAge ?? 0) > 0)
                      Text(
                        '${s.displayAge}y',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
