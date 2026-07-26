import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/academic/enrollment_display.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../providers/teacher_attendance_provider.dart';

/// Quick actions for teachers (and similar roles) to track and contact a student.
class StudentCareSheet extends StatelessWidget {
  final StudentModel student;
  final Color accentColor;

  const StudentCareSheet({
    super.key,
    required this.student,
    this.accentColor = AppTheme.primaryBlue,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentModel student,
    Color accentColor = AppTheme.primaryBlue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StudentCareSheet(student: student, accentColor: accentColor),
    );
  }

  Future<void> _messageParent(BuildContext context) async {
    final teacher = context.read<AuthProvider>().currentUser;
    if (teacher == null) return;

    final parent = await context
        .read<MessagingProvider>()
        .parentContactsFromRoster([student]);
    if (!context.mounted || parent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find parent contact for this student.')),
      );
      return;
    }

    final thread = await context.read<MessagingProvider>().ensureTeacherToParentThread(
          teacher: teacher,
          contact: parent.first,
        );
    if (!context.mounted) return;
    if (thread == null) {
      final err = context.read<MessagingProvider>().errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    Navigator.pop(context);
    AppRoutes.push(context, AppRoutes.chat, arguments: thread);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final school = context.watch<SchoolAdminProvider>();
    final attendance = context.watch<TeacherAttendanceProvider>();
    final gradeLabel = EnrollmentDisplay.classOrGradeLabel(
      school,
      student.classRoomId,
      gradeLevelId: student.gradeLevelId,
    );
    final present = attendance.isPresent(student.id);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                child: Text(
                  student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      gradeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.fact_check_rounded,
            label: 'Attendance today',
            value: present ? 'Present' : 'Not marked present',
            valueColor: present ? const Color(0xFF7ED321) : Colors.orange,
            isDark: isDark,
          ),
          if (student.healthModuleEnabled) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.health_and_safety_rounded,
              label: 'Health module',
              value: 'Enabled — clinic can track growth & vaccines',
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _messageParent(context),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Message parent'),
              style: FilledButton.styleFrom(backgroundColor: accentColor),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Use Attendance tab to update ${student.fullName}\'s status for today.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.how_to_reg_rounded),
              label: const Text('Mark attendance'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: valueColor ?? (isDark ? Colors.white : AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
