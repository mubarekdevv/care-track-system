import 'package:flutter/material.dart';

import '../../core/academic/enrollment_display.dart';
import '../../core/academic/grade_naming.dart';
import '../../core/academic/academic_resolver.dart';
import '../../core/theme/app_theme.dart';
import '../../models/class_subject_model.dart';

class GradeTeacherPreviewPanel extends StatelessWidget {
  final GradeEnrollmentPreview? preview;
  final bool isLoading;
  final SectionEnrollmentStatus? enrollmentStatus;

  const GradeTeacherPreviewPanel({
    super.key,
    required this.preview,
    this.isLoading = false,
    this.enrollmentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (preview == null || preview!.teachers.isEmpty) {
      if (enrollmentStatus != null && !enrollmentStatus!.hasSubjectSlots) {
        return _emptyNote(
          isDark,
          'No subjects configured for this class yet.',
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_rounded,
                size: 20, color: isDark ? Colors.white70 : AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                EnrollmentDisplay.teachersForGradeTitle(
                  preview!.grade.name,
                  classRoomName: preview!.classRoom?.name,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
              ),
            ),
            if (enrollmentStatus?.canEnroll == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ready to enroll',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softGreen,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          enrollmentStatus?.canEnroll == true
              ? 'All subjects have teachers assigned.'
              : 'Some subjects still need a teacher before you can enroll.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        ...preview!.teachers.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TeacherAssignmentCard(teacher: t, isDark: isDark),
          ),
        ),
      ],
    );
  }

  Widget _emptyNote(bool isDark, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _TeacherAssignmentCard extends StatelessWidget {
  final AssignedTeacherView teacher;
  final bool isDark;

  const _TeacherAssignmentCard({
    required this.teacher,
    required this.isDark,
  });

  IconData _iconForKey(String? key) {
    switch (key) {
      case 'calculate':
        return Icons.calculate_rounded;
      case 'translate':
        return Icons.translate_rounded;
      case 'science':
        return Icons.biotech_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'computer':
        return Icons.computer_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color _accentForSubject(String name) {
    final n = name.toLowerCase();
    if (n.contains('math')) return const Color(0xFF4A90D9);
    if (n.contains('english')) return const Color(0xFF9013FE);
    if (n.contains('science')) return const Color(0xFF7ED321);
    if (n.contains('art') || n.contains('music')) return const Color(0xFFE2894A);
    if (n.contains('physical') || n.contains('sport')) return const Color(0xFF50E3C2);
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForSubject(teacher.subject.name);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : accent.withValues(alpha: 0.2),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(
                _iconForKey(teacher.subjectIconKey),
                color: accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.subject.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    teacher.isLinked ? teacher.teacherName : 'Teacher not assigned yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: teacher.isLinked ? null : Colors.orange.shade800,
                    ),
                  ),
                  if (!teacher.isLinked && teacher.teacherName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Catalog: ${teacher.teacherName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (teacher.isLinked &&
                      teacher.teacherEmail != null &&
                      teacher.teacherEmail!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            size: 14,
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            teacher.teacherEmail!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (teacher.isLinked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Linked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
