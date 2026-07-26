import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/academic_models.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_homework_provider.dart';

/// Bottom sheet for teachers to enter grades for a homework assignment.
class GradeEntrySheet extends StatefulWidget {
  final AssignmentModel assignment;
  final List<StudentModel> roster;

  const GradeEntrySheet({
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
      builder: (_) => GradeEntrySheet(assignment: assignment, roster: roster),
    );
  }

  @override
  State<GradeEntrySheet> createState() => _GradeEntrySheetState();
}

class _GradeEntrySheetState extends State<GradeEntrySheet> {
  final _scores = <String, TextEditingController>{};
  bool _saving = false;

  List<StudentModel> get _classRoster => widget.roster
      .where((s) => s.classRoomId == widget.assignment.classRoomId)
      .toList();

  @override
  void initState() {
    super.initState();
    for (final student in _classRoster) {
      _scores[student.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _scores.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final teacherId = context.read<AuthProvider>().currentUser?.uid;
    if (teacherId == null) return;

    final scoresByStudentId = <String, double>{};
    for (final entry in _scores.entries) {
      final score = double.tryParse(entry.value.text.trim());
      if (score != null && score >= 0 && score <= 100) {
        scoresByStudentId[entry.key] = score;
      }
    }

    if (scoresByStudentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one score between 0 and 100.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await context.read<TeacherHomeworkProvider>().publishGradesForAssignment(
            teacherId: teacherId,
            assignment: widget.assignment,
            scoresByStudentId: scoresByStudentId,
            classRoster: _classRoster,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Published grades for $saved student${saved == 1 ? '' : 's'}. Parents will see them in Reports.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.softGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<TeacherHomeworkProvider>().error ?? 'Could not save grades.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final roster = _classRoster;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Grades',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.assignment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (roster.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No enrolled students in this class yet.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: roster.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final student = roster[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _scores[student.id],
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '0–100',
                            isDense: true,
                            filled: true,
                            fillColor:
                                isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving || roster.isEmpty ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ED321),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Publish grades',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
