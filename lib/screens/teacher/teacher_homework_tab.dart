import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/academic/enrollment_display.dart';
import '../../core/theme/app_theme.dart';
import '../../models/academic_models.dart';
import '../../models/teacher_teaching_slot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_attendance_provider.dart';
import '../../providers/teacher_homework_provider.dart';
import '../../providers/teacher_overview_provider.dart';
import '../../widgets/common/education_empty_state.dart';
import '../../widgets/dashboard/dashboard_tab_scaffold.dart';
import '../../widgets/teacher/assignment_completion_sheet.dart';

class TeacherHomeworkTab extends StatefulWidget {
  const TeacherHomeworkTab({super.key});

  @override
  State<TeacherHomeworkTab> createState() => _TeacherHomeworkTabState();
}

class _TeacherHomeworkTabState extends State<TeacherHomeworkTab> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TeacherTeachingSlot? _selectedSlot;
  DateTime? _dueDate;
  bool _publishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _classLabel(AssignmentModel assignment, TeacherOverviewProvider overview) {
    for (final slot in overview.slots) {
      if (slot.classRoomId == assignment.classRoomId &&
          slot.subjectId == assignment.subjectId) {
        return EnrollmentDisplay.teacherSlotLine(slot.gradeName, slot.className);
      }
    }
    return 'Class';
  }

  String _subjectLabel(AssignmentModel assignment, TeacherOverviewProvider overview) {
    for (final slot in overview.slots) {
      if (slot.subjectId == assignment.subjectId) {
        return slot.subjectName;
      }
    }
    return 'Subject';
  }

  Color _accentFor(String subjectName) {
    final n = subjectName.toLowerCase();
    if (n.contains('math')) return const Color(0xFF4A90E2);
    if (n.contains('english')) return const Color(0xFF7ED321);
    if (n.contains('science')) return const Color(0xFF9013FE);
    return const Color(0xFFE2894A);
  }

  void _showAddAssignmentSheet() {
    final overview = context.read<TeacherOverviewProvider>();
    if (overview.slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ask admin to assign you to a class before creating homework.'),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    _titleController.clear();
    _descriptionController.clear();
    _dueDate = null;
    _selectedSlot = overview.slots.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create assignment',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Class & subject',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TeacherTeachingSlot>(
                    initialValue: _selectedSlot,
                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: overview.slots
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.displayLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setSheetState(() => _selectedSlot = val),
                  ),
                  const SizedBox(height: 16),
                  const Text('Title',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Fractions worksheet',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Instructions (optional)',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Due date',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setSheetState(() => _dueDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                              size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _dueDate != null
                                ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                                : 'Select due date',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _publishing
                          ? null
                          : () async {
                              final slot = _selectedSlot;
                              if (slot == null ||
                                  _titleController.text.trim().isEmpty ||
                                  _dueDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Complete title, class, and due date.'),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => _publishing = true);
                              final uid = context.read<AuthProvider>().currentUser?.uid;
                              if (uid == null) return;
                              final ok = await context
                                  .read<TeacherHomeworkProvider>()
                                  .publishAssignment(
                                    teacherId: uid,
                                    slot: slot,
                                    title: _titleController.text,
                                    description: _descriptionController.text,
                                    dueAt: _dueDate!,
                                  );
                              if (!context.mounted) return;
                              setSheetState(() => _publishing = false);
                              if (ok) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Assignment published to Firestore.'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.read<TeacherHomeworkProvider>().error ??
                                          'Could not publish.',
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9013FE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _publishing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Publish assignment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homework = context.watch<TeacherHomeworkProvider>();
    final overview = context.watch<TeacherOverviewProvider>();
    final roster = context.watch<TeacherAttendanceProvider>().roster;

    return DashboardTabScaffold(
      title: 'Homework & Tasks',
      floatingActionButton: overview.slots.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddAssignmentSheet,
              backgroundColor: const Color(0xFF9013FE),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('New assignment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: homework.isLoading
          ? const Center(child: CircularProgressIndicator())
          : homework.assignments.isEmpty
              ? EducationEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No homework published yet',
                  message: overview.slots.isEmpty
                      ? 'Get assigned to a class first, then create assignments for your students.'
                      : 'Tap “New assignment” to publish homework to Firestore. Students will see it after parent apps load class homework (next phase).',
                  action: overview.slots.isEmpty
                      ? null
                      : TextButton(
                          onPressed: _showAddAssignmentSheet,
                          child: const Text('Create first assignment'),
                        ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: homework.assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final assignment = homework.assignments[index];
                    final subject = _subjectLabel(assignment, overview);
                    final accent = _accentFor(subject);
                    final due = assignment.dueAt != null
                        ? DateFormat('MMM d, yyyy').format(assignment.dueAt!)
                        : 'No due date';
                    final turnedIn = homework.submissionCountFor(assignment.id);
                    final total = overview.studentCountForClass(assignment.classRoomId);

                    return Material(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => AssignmentCompletionSheet.show(
                          context,
                          assignment: assignment,
                          roster: roster,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    subject,
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  assignment.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _classLabel(assignment, overview),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                if (assignment.description != null &&
                                    assignment.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    assignment.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month_rounded,
                                        size: 14,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : AppTheme.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Due: $due',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.task_alt_rounded,
                                        size: 14,
                                        color: turnedIn > 0
                                            ? const Color(0xFF7ED321)
                                            : AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$turnedIn / $total turned in',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: turnedIn > 0
                                            ? const Color(0xFF7ED321)
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
