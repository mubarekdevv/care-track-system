import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/academic/grade_naming.dart';
import '../../core/catalog/academic_catalog.dart';
import '../../core/config/school_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/class_room_model.dart';
import '../../models/grade_level_model.dart';
import '../../models/subject_model.dart';
import '../../models/user_model.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/admin/assign_teacher_dialog.dart';
import '../../widgets/admin/grade_enrolled_students_panel.dart';
import '../../widgets/admin/admin_healthcare_staff_panel.dart';

/// Grades + sections (classes) in one place — Grade 1 → A, B, …
class AdminGradesAndSectionsTab extends StatelessWidget {
  const AdminGradesAndSectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _InfoBanner(
              icon: Icons.school_rounded,
              title: 'Grade levels',
              body: SchoolConfig.gradeOnlyEnrollment
                  ? 'Each grade is one class (e.g. Grade 1). Pick levels from the menu to avoid typos. '
                      'Assign every subject in Staff before parents can enroll.'
                  : 'A grade is the year level (e.g. Grade 1). Sections are groups within that grade '
                      '(e.g. Grade 1-A and Grade 1-B). Each grade name must be unique.',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _AddGradeCard(admin: admin),
          ),
        ),
        if (admin.grades.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              icon: Icons.layers_outlined,
              message: 'No grades yet. Add Grade 1, Grade 2… or load the sample catalog from Home.',
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final grade = admin.grades[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _GradeSectionCard(grade: grade, admin: admin),
                );
              },
              childCount: admin.grades.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class AdminSubjectsTab extends StatefulWidget {
  const AdminSubjectsTab({super.key});

  @override
  State<AdminSubjectsTab> createState() => _AdminSubjectsTabState();
}

class _AdminSubjectsTabState extends State<AdminSubjectsTab> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _add(SchoolAdminProvider admin) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final ok = await admin.addSubject(
      name,
      code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
    );
    if (ok && mounted) {
      _nameController.clear();
      _codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _InfoBanner(
          icon: Icons.menu_book_rounded,
          title: 'Subjects',
          body: 'Courses taught at your school (Math, Science…). Assign teachers to subjects per section.',
        ),
        const SizedBox(height: 16),
        _AdminInputCard(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject name',
                  hintText: 'Mathematics',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code (optional)',
                  hintText: 'MATH',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _add(admin),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add subject'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${admin.subjects.length} active subject(s)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (admin.subjects.isEmpty)
          const _EmptyState(
            icon: Icons.menu_book_outlined,
            message: 'No subjects yet.',
          )
        else
          ...admin.subjects.map(
            (s) => _SubjectTile(
              subject: s,
              onRemove: () => _confirmRemove(context, admin, s),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    SchoolAdminProvider admin,
    SubjectModel subject,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove subject?'),
        content: Text('Deactivate "${subject.name}"? Existing assignments stay in history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await admin.removeSubject(subject.id);
  }
}

class AdminTeachersTab extends StatefulWidget {
  const AdminTeachersTab({super.key});

  @override
  State<AdminTeachersTab> createState() => _AdminTeachersTabState();
}

class _AdminTeachersTabState extends State<AdminTeachersTab> {
  String? _classId;
  String? _subjectId;
  String? _teacherId;

  Future<void> _assign(SchoolAdminProvider admin) async {
    if (_classId == null || _subjectId == null || _teacherId == null) return;
    final ok = await admin.assignTeacher(
      classRoomId: _classId!,
      subjectId: _subjectId!,
      teacherId: _teacherId!,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Teacher assigned. They can now see students in that grade for attendance and homework.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();
    final teachers = admin.teachers;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _InfoBanner(
          icon: Icons.groups_rounded,
          title: 'How teacher assignment works',
          body: SchoolConfig.gradeOnlyEnrollment
              ? '1. Teacher registers and selects which subjects they teach (your subject list).\n'
                  '2. You link them to the school (Link / Link teachers below).\n'
                  '3. Tap Assign — only teachers qualified for that subject appear.\n\n'
                  'Sample names on empty rows are curriculum placeholders, not real accounts.'
              : 'Teachers register with role Teacher. Link them to your school, '
                  'then assign each teacher to a grade + subject below.',
        ),
        if (admin.pendingTeachers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PendingTeachersPanel(admin: admin),
        ],
        if (admin.unlinkedSubjectSlotCount > 0) ...[
          const SizedBox(height: 8),
          _WarningBanner(
            title: '${admin.unlinkedSubjectSlotCount} subject(s) still need a teacher',
            body: 'Tap Assign next to each subject below and choose a linked teacher account.',
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final n = await admin.linkAllTeachersToSchool();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    n > 0
                        ? 'Linked $n teacher(s) to school and refreshed class access for all teachers.'
                        : 'Refreshed class access for all teachers. Assign them to grades below.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.link_rounded),
          label: const Text('Link teachers & refresh roster access'),
        ),
        const SizedBox(height: 8),
        Text(
          SchoolConfig.gradeOnlyEnrollment
              ? 'Example for Grade 2: tap Assign beside Mathematics → pick the real teacher '
                  '(e.g. abel) → Assign. Repeat for Science, English, etc.'
              : 'After a teacher registers: tap above, then assign each teacher to a grade + subject.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'School teachers (${teachers.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (teachers.isEmpty)
          const _EmptyState(
            icon: Icons.person_off_outlined,
            message: 'No teachers linked. Ask staff to sign up as Teacher, then tap Link above.',
          )
        else
          ...teachers.map(
            (t) => _TeacherTile(
              teacher: t,
              admin: admin,
              onRemove: () => _confirmRemoveTeacher(context, admin, t),
            ),
          ),
        const AdminHealthcareStaffPanel(),
        const SizedBox(height: 28),
        if (admin.classAssignments.isNotEmpty) ...[
          Text(
            SchoolConfig.gradeOnlyEnrollment
                ? 'Subjects by grade'
                : 'Subject slots by class',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Orange rows need a real teacher. Tap Assign to choose who teaches that subject.',
            style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          if (SchoolConfig.gradeOnlyEnrollment)
            ...admin.grades.map((grade) {
              final room = admin.primaryClassForGrade(grade.id);
              if (room == null) return const SizedBox.shrink();
              return _SectionAssignmentCard(
                section: room,
                admin: admin,
                titleOverride: grade.name,
                onAssignSlot: (classId, subjectId) {
                  showAssignTeacherDialog(
                    context,
                    classRoomId: classId,
                    subjectId: subjectId,
                  );
                },
              );
            })
          else
            ...admin.classes.map(
              (section) => _SectionAssignmentCard(
                section: section,
                admin: admin,
                onAssignSlot: (classId, subjectId) {
                  showAssignTeacherDialog(
                    context,
                    classRoomId: classId,
                    subjectId: subjectId,
                  );
                },
              ),
            ),
          const SizedBox(height: 28),
        ],
        Text(
          'Manual assignment (optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Use the form below only if you prefer dropdowns instead of tapping Assign above.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        _AdminInputCard(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _classId,
                decoration: const InputDecoration(
                  labelText: SchoolConfig.gradeOnlyEnrollment ? 'Grade' : 'Class',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: (SchoolConfig.gradeOnlyEnrollment
                        ? admin.grades
                            .map((g) => admin.primaryClassForGrade(g.id))
                            .whereType<ClassRoomModel>()
                        : admin.classes)
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(admin.classDisplayLabel(c)),
                        ))
                    .toList(),
                onChanged: teachers.isEmpty ? null : (v) => setState(() => _classId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _subjectId,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: admin.subjects
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: teachers.isEmpty
                    ? null
                    : (v) => setState(() {
                          _subjectId = v;
                          if (_teacherId != null && _classId != null) {
                            final t = teachers
                                .where((x) => x.uid == _teacherId)
                                .firstOrNull;
                            if (t != null &&
                                !admin.teacherCanTeachSubject(
                                  t,
                                  v ?? '',
                                  gradeLevelId:
                                      admin.gradeLevelIdForClassRoom(_classId!),
                                )) {
                              _teacherId = null;
                            }
                          }
                        }),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _teacherId,
                decoration: InputDecoration(
                  labelText: 'Teacher',
                  helperText: _classId == null || _subjectId == null
                      ? 'Select grade and subject first'
                      : 'Only teachers registered for that grade + subject',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: (_subjectId == null
                        ? <UserModel>[]
                        : admin.teachersEligibleForSubject(
                            _subjectId!,
                            classRoomId: _classId,
                          ))
                    .map((t) => DropdownMenuItem(value: t.uid, child: Text(t.fullName)))
                    .toList(),
                onChanged: _subjectId == null || teachers.isEmpty
                    ? null
                    : (v) => setState(() => _teacherId = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: teachers.isEmpty ? null : () => _assign(admin),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save assignment'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemoveTeacher(
    BuildContext context,
    SchoolAdminProvider admin,
    UserModel teacher,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove teacher from school?'),
        content: Text(
          'Unlink ${teacher.fullName} from this school and clear their class assignments. '
          'Their login account is not deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await admin.removeTeacherFromSchool(teacher.uid);
  }
}

class _PendingTeachersPanel extends StatelessWidget {
  final SchoolAdminProvider admin;

  const _PendingTeachersPanel({required this.admin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${admin.pendingTeachers.length} teacher(s) waiting to be linked',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'These accounts registered as Teacher but are not linked to your school yet.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...admin.pendingTeachers.map(
            (t) => _PendingTeacherTile(
              teacher: t,
              admin: admin,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingTeacherTile extends StatelessWidget {
  final UserModel teacher;
  final SchoolAdminProvider admin;

  const _PendingTeacherTile({required this.teacher, required this.admin});

  String? _prefGrade() {
    final id = teacher.teacherProfile?.preferredGradeLevelId;
    if (id == null) return null;
    return admin.gradeNameForId(id);
  }

  @override
  Widget build(BuildContext context) {
    final grade = _prefGrade();
    final subjects = admin.teachableSubjectsLabel(teacher);
    final prefs = grade != null
        ? 'Prefers $grade · teaches: $subjects'
        : 'Profile setup not completed yet';

    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : AppTheme.inputBorder,
        ),
      ),
      child: ListTile(
        dense: true,
        title: Text(teacher.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher.email, style: const TextStyle(fontSize: 12)),
            Text(prefs, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        isThreeLine: true,
        trailing: FilledButton.tonal(
          onPressed: () async {
            final ok = await admin.linkTeacherToSchool(teacher.uid);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Linked ${teacher.fullName} to your school.'
                        : admin.error ?? 'Could not link teacher.',
                  ),
                ),
              );
            }
          },
          child: const Text('Link'),
        ),
      ),
    );
  }
}

class _SectionAssignmentCard extends StatelessWidget {
  final ClassRoomModel section;
  final SchoolAdminProvider admin;
  final String? titleOverride;
  final void Function(String classId, String subjectId) onAssignSlot;

  const _SectionAssignmentCard({
    required this.section,
    required this.admin,
    required this.onAssignSlot,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final slots = admin.assignmentsForSection(section.id);
    if (slots.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counts = admin.sectionAssignmentCounts(section.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titleOverride ?? admin.classDisplayLabel(section),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  '${counts.$1}/${counts.$2} linked',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: counts.$1 == counts.$2 ? AppTheme.softGreen : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...slots.map((slot) {
              final linked = admin.isAssignmentLinked(slot);
              final subjectName = admin.subjectNameForId(slot.subjectId) ?? 'Subject';
              final teacherLabel = admin.assignmentTeacherLabel(slot);
              return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        linked ? Icons.check_circle_rounded : Icons.person_outline_rounded,
                        size: 18,
                        color: linked ? AppTheme.softGreen : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subjectName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              teacherLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: linked
                                    ? AppTheme.textSecondary
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!linked)
                        FilledButton.tonal(
                          onPressed: () => onAssignSlot(section.id, slot.subjectId),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Assign'),
                        ),
                    ],
                  ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ——— Grade + section cards ———

class _GradeSectionCard extends StatefulWidget {
  final GradeLevelModel grade;
  final SchoolAdminProvider admin;

  const _GradeSectionCard({required this.grade, required this.admin});

  @override
  State<_GradeSectionCard> createState() => _GradeSectionCardState();
}

class _GradeSectionCardState extends State<_GradeSectionCard> {
  final _sectionController = TextEditingController();
  bool _expanded = true;

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _addSection() async {
    final code = _sectionController.text.trim();
    if (code.isEmpty) return;
    final ok = await widget.admin.addSectionToGrade(
      gradeLevelId: widget.grade.id,
      sectionCode: code,
    );
    if (ok && mounted) _sectionController.clear();
    if (!ok && mounted && widget.admin.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.admin.error!)),
      );
    }
  }

  Future<void> _removeGrade() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove grade?'),
        content: Text(
          'Remove "${widget.grade.name}" and all its sections? '
          'Students already enrolled keep their records.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await widget.admin.removeGradeLevel(widget.grade.id);
  }

  String _gradeSubtitle(List<ClassRoomModel> sections) {
    if (SchoolConfig.gradeOnlyEnrollment) {
      final room = widget.admin.primaryClassForGrade(widget.grade.id);
      if (room == null) return 'No class yet — add subjects in Staff';
      final status = widget.admin.sectionEnrollmentStatus(room.id);
      if (status.canEnroll) return 'Ready — parents can enroll';
      final counts = widget.admin.sectionAssignmentCounts(room.id);
      return '${counts.$1}/${counts.$2} teachers assigned';
    }
    if (sections.isEmpty) return 'No sections yet';
    var ready = 0;
    for (final s in sections) {
      if (widget.admin.sectionEnrollmentStatus(s.id).canEnroll) ready++;
    }
    return '${sections.length} section(s) · $ready ready for enrollment';
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.admin.sectionsForGrade(widget.grade.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
            child: Text(
              GradeNaming.displayBadge(widget.grade.name, widget.grade.sortOrder),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
                fontSize: 13,
              ),
            ),
          ),
          title: Text(
            widget.grade.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            _gradeSubtitle(sections),
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _removeGrade,
            tooltip: 'Remove grade',
          ),
          children: [
            if (SchoolConfig.gradeOnlyEnrollment) ...[
              _GradeStaffingPanel(grade: widget.grade, admin: widget.admin),
            ] else ...[
              if (sections.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No sections yet. Add A, B… so parents can choose (e.g. Grade 1-A).',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sections.map((s) => _SectionChip(
                    section: s,
                    gradeName: widget.grade.name,
                    admin: widget.admin,
                    onRemove: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove section?'),
                          content: Text('Remove "${s.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await widget.admin.removeClassRoom(s.id);
                      }
                    },
                  )).toList(),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sectionController,
                      decoration: InputDecoration(
                        labelText: 'New section',
                        hintText: 'A, B, Lions…',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addSection,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddGradeCard extends StatefulWidget {
  final SchoolAdminProvider admin;

  const _AddGradeCard({required this.admin});

  @override
  State<_AddGradeCard> createState() => _AddGradeCardState();
}

class _AddGradeCardState extends State<_AddGradeCard> {
  int? _selectedLevel;

  Future<void> _add() async {
    final level = _selectedLevel;
    if (level == null) return;
    final ok = await widget.admin.addGradeFromCatalogLevel(level);
    if (!mounted) return;
    if (ok) {
      setState(() => _selectedLevel = null);
    } else if (widget.admin.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.admin.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.admin.availableCatalogLevelsToAdd();
    final max = widget.admin.effectiveMaxCatalogGradeLevel;
    if (max <= 0) {
      return _AdminInputCard(
        child: Text(
          'Set your grade range on Home (Load curriculum), then add grades here.',
          style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9)),
        ),
      );
    }
    if (available.isEmpty) {
      return _AdminInputCard(
        child: Text(
          'All grades through Grade $max are already added. '
          'Use Home → Change max to extend the range.',
          style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9)),
        ),
      );
    }
    if (_selectedLevel == null || !available.contains(_selectedLevel)) {
      _selectedLevel = available.first;
    }

    return _AdminInputCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _selectedLevel,
              decoration: InputDecoration(
                labelText: 'Add grade level',
                helperText:
                    'Standard levels 1–$max only (set on Home). Prevents naming typos.',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: available
                  .map((level) {
                    final name = AcademicCatalog.templateForLevel(level).displayName;
                    return DropdownMenuItem(value: level, child: Text(name));
                  })
                  .toList(),
              onChanged: widget.admin.isBusy
                  ? null
                  : (v) => setState(() => _selectedLevel = v),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: widget.admin.isBusy ? null : _add,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(widget.admin.isBusy ? '…' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _GradeStaffingPanel extends StatefulWidget {
  final GradeLevelModel grade;
  final SchoolAdminProvider admin;

  const _GradeStaffingPanel({required this.grade, required this.admin});

  @override
  State<_GradeStaffingPanel> createState() => _GradeStaffingPanelState();
}

class _GradeStaffingPanelState extends State<_GradeStaffingPanel> {
  String? _subjectToAdd;

  Future<void> _addSubject() async {
    final subjectId = _subjectToAdd;
    if (subjectId == null) return;
    final ok = await widget.admin.addSubjectToGrade(
      gradeLevelId: widget.grade.id,
      subjectId: subjectId,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _subjectToAdd = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject added to this grade.')),
      );
    } else if (widget.admin.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.admin.error!)),
      );
    }
  }

  Future<void> _removeSubject(String subjectId, String subjectName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove subject from grade?'),
        content: Text(
          'Remove "$subjectName" from ${widget.grade.name}? '
          'Teacher assignment for this slot will be cleared.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removed = await widget.admin.removeSubjectFromGrade(
      gradeLevelId: widget.grade.id,
      subjectId: subjectId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed ? 'Subject removed from grade.' : widget.admin.error ?? 'Could not remove.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final room = admin.primaryClassForGrade(widget.grade.id);
    if (room == null) {
      return const Text(
        'No class linked to this grade yet. Remove and re-add the grade from the menu above.',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
      );
    }
    final status = admin.sectionEnrollmentStatus(room.id);
    final counts = admin.sectionAssignmentCounts(room.id);
    final color = status.canEnroll
        ? AppTheme.softGreen
        : counts.$1 > 0
            ? Colors.orange
            : Colors.redAccent;
    final slots = admin.subjectSlotsForGrade(widget.grade.id);
    final available = admin.subjectsAvailableToAddToGrade(widget.grade.id);
    if (_subjectToAdd != null &&
        !available.any((s) => s.id == _subjectToAdd)) {
      _subjectToAdd = available.isNotEmpty ? available.first.id : null;
    } else if (_subjectToAdd == null && available.isNotEmpty) {
      _subjectToAdd = available.first.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(
                status.canEnroll ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.canEnroll
                      ? 'All ${counts.$2} subjects have teachers — parents can enroll.'
                      : '${counts.$1} of ${counts.$2} subjects have teachers. '
                          'Open Staff to assign the rest.',
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        if (status.unassignedSubjectNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Needs teacher: ${status.unassignedSubjectNames.join(', ')}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Subjects in this grade',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        if (slots.isEmpty)
          const Text(
            'No subjects yet. Add from your school list below.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: slots.map((slot) {
              final name = admin.subjectNameForId(slot.subjectId) ?? 'Subject';
              final hasTeacher = slot.teacherId.isNotEmpty;
              return InputChip(
                label: Text(
                  hasTeacher ? name : '$name (no teacher)',
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: Icon(
                  hasTeacher ? Icons.check_circle_outline : Icons.schedule,
                  size: 16,
                  color: hasTeacher ? AppTheme.softGreen : Colors.orange,
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeSubject(slot.subjectId, name),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        if (available.isEmpty)
          Text(
            admin.subjects.isEmpty
                ? 'Add subjects on the Subjects tab first.'
                : 'All school subjects are already in this grade.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _subjectToAdd,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Add subject from school list',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: available
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _subjectToAdd = v),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addSubject,
                child: const Text('Add'),
              ),
            ],
          ),
        GradeEnrolledStudentsPanel(
          classRoomId: room.id,
          gradeName: widget.grade.name,
        ),
      ],
    );
  }
}

class _SectionChip extends StatelessWidget {
  final ClassRoomModel section;
  final String gradeName;
  final SchoolAdminProvider admin;
  final VoidCallback onRemove;

  const _SectionChip({
    required this.section,
    required this.gradeName,
    required this.admin,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final label = SchoolAdminProvider.sectionLabel(section, gradeName);
    final counts = admin.sectionAssignmentCounts(section.id);
    final ready = counts.$2 > 0 && counts.$1 == counts.$2;
    final partial = counts.$1 > 0 && counts.$1 < counts.$2;
    final color = ready
        ? AppTheme.softGreen
        : partial
            ? Colors.orange
            : Colors.redAccent;

    return InputChip(
      avatar: Icon(
        ready ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
        size: 16,
        color: color,
      ),
      label: Text(
        counts.$2 == 0 ? label : '$label (${counts.$1}/${counts.$2} teachers)',
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      onDeleted: onRemove,
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onRemove;

  const _SubjectTile({required this.subject, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : AppTheme.inputBorder,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF9013FE).withValues(alpha: 0.12),
          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF9013FE)),
        ),
        title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subject.code != null ? Text(subject.code!) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  final UserModel teacher;
  final SchoolAdminProvider admin;
  final VoidCallback onRemove;

  const _TeacherTile({
    required this.teacher,
    required this.admin,
    required this.onRemove,
  });

  String? get _prefGrade {
    final id = teacher.teacherProfile?.preferredGradeLevelId;
    if (id == null) return null;
    return admin.gradeNameForId(id);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = admin.teachableSubjectsLabel(teacher);
    final prefs = _prefGrade != null
        ? 'Prefers $_prefGrade · teaches: $subjects'
        : 'Profile setup not completed yet';
    final assignmentCount = admin.classAssignments
        .where((a) => a.teacherId == teacher.uid)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : AppTheme.inputBorder,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE2894A).withValues(alpha: 0.15),
          child: Text(
            teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : 'T',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE2894A)),
          ),
        ),
        title: Text(teacher.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher.email),
            const SizedBox(height: 2),
            Text(
              '$prefs · $assignmentCount assignment(s)',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String title;
  final String body;

  const _WarningBanner({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.softGreen.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, height: 1.45, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminInputCard extends StatelessWidget {
  final Widget child;

  const _AdminInputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
