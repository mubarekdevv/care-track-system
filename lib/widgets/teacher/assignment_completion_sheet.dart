import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/academic/enrollment_display.dart';
import '../../core/config/school_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/academic_models.dart';
import '../../models/student_model.dart';
import '../../providers/school_admin_provider.dart';
import '../../providers/teacher_homework_provider.dart';
import 'grade_entry_sheet.dart';

/// Teacher view: who turned in homework vs still pending.
class AssignmentCompletionSheet extends StatelessWidget {
  final AssignmentModel assignment;
  final List<StudentModel> roster;

  const AssignmentCompletionSheet({
    super.key,
    required this.assignment,
    required this.roster,
  });

  static Future<void> show(
    BuildContext context, {
    required AssignmentModel assignment,
    required List<StudentModel> roster,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AssignmentCompletionSheet(
        assignment: assignment,
        roster: roster,
      ),
    );
  }

  List<StudentModel> _classRoster(SchoolAdminProvider school) {
    if (SchoolConfig.gradeOnlyEnrollment) {
      final gradeId = school.gradeLevelIdForClassRoom(assignment.classRoomId);
      if (gradeId != null && gradeId.isNotEmpty) {
        return roster.where((s) => s.gradeLevelId == gradeId).toList();
      }
    }
    return roster.where((s) => s.classRoomId == assignment.classRoomId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homework = context.watch<TeacherHomeworkProvider>();
    final school = context.watch<SchoolAdminProvider>();
    final classRoster = _classRoster(school);
    final turnedIn = homework.submittedStudentIdsFor(assignment.id);
    final done = classRoster.where((s) => turnedIn.contains(s.id)).toList();
    final pending =
        classRoster.where((s) => !turnedIn.contains(s.id)).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                assignment.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                '${done.length} of ${classRoster.length} turned in',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        GradeEntrySheet.show(
                          context,
                          assignment: assignment,
                          roster: roster,
                        );
                      },
                      icon: const Icon(Icons.grade_rounded, size: 18),
                      label: const Text('Enter grades'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (done.isNotEmpty) ...[
                      const Text(
                        'Turned in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF7ED321),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...done.map(
                        (s) => _StudentRow(
                          student: s,
                          school: school,
                          isDark: isDark,
                          done: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Not turned in yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pending.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Everyone in your roster has turned this in!',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...pending.map(
                        (s) => _StudentRow(
                          student: s,
                          school: school,
                          isDark: isDark,
                          done: false,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  final StudentModel student;
  final SchoolAdminProvider school;
  final bool isDark;
  final bool done;

  const _StudentRow({
    required this.student,
    required this.school,
    required this.isDark,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final grade = EnrollmentDisplay.classOrGradeLabel(
      school,
      student.classRoomId,
      gradeLevelId: student.gradeLevelId,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? const Color(0xFF7ED321).withValues(alpha: 0.35)
              : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
            color: done ? const Color(0xFF7ED321) : Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  grade,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            done ? 'Done' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: done ? const Color(0xFF7ED321) : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
