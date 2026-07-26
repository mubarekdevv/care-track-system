import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/school_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/grade_level_model.dart';
import '../../models/staff_profile_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';

/// Teacher setup: add multiple grades; subjects shown per grade from school curriculum.
class TeacherProfileSetupScreen extends StatefulWidget {
  const TeacherProfileSetupScreen({super.key, this.isFirstLogin = false});

  /// Shown right after sign-in when registration did not include grades/subjects.
  final bool isFirstLogin;

  @override
  State<TeacherProfileSetupScreen> createState() =>
      _TeacherProfileSetupScreenState();
}

class _TeacherProfileSetupScreenState extends State<TeacherProfileSetupScreen> {
  /// gradeLevelId → subject ids selected for that grade
  final Map<String, Set<String>> _byGrade = {};
  String? _activeGradeId;
  final Set<String> _draftSubjectIds = {};
  bool _saving = false;
  bool _deferring = false;
  bool _loadedExisting = false;

  void _loadExistingProfile(AuthProvider auth) {
    if (_loadedExisting) return;
    final profile = auth.currentUser?.teacherProfile;
    if (profile == null) return;
    _loadedExisting = true;
    for (final t in profile.teachingsByGrade) {
      _byGrade[t.gradeLevelId] = Set<String>.from(t.subjectIds);
    }
  }

  List<GradeLevelModel> _gradesAvailableToPick(SchoolAdminProvider school) {
    return school.grades.where((g) => !_byGrade.containsKey(g.id)).toList();
  }

  void _selectGrade(String gradeId, SchoolAdminProvider school) {
    setState(() {
      _activeGradeId = gradeId;
      _draftSubjectIds
        ..clear()
        ..addAll(_byGrade[gradeId] ?? {});
    });
  }

  void _commitActiveGrade() {
    if (_activeGradeId == null) return;
    if (_draftSubjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one subject for this grade.')),
      );
      return;
    }
    setState(() {
      _byGrade[_activeGradeId!] = Set<String>.from(_draftSubjectIds);
      _activeGradeId = null;
      _draftSubjectIds.clear();
    });
  }

  void _editGrade(String gradeId) {
    setState(() {
      _activeGradeId = gradeId;
      _draftSubjectIds
        ..clear()
        ..addAll(_byGrade[gradeId] ?? {});
    });
  }

  void _removeGrade(String gradeId) {
    setState(() {
      _byGrade.remove(gradeId);
      if (_activeGradeId == gradeId) {
        _activeGradeId = null;
        _draftSubjectIds.clear();
      }
    });
  }

  Future<void> _save() async {
    if (_byGrade.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one grade and its subjects.'),
        ),
      );
      return;
    }
    if (_activeGradeId != null && _draftSubjectIds.isNotEmpty) {
      _commitActiveGrade();
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final teachings = _byGrade.entries
        .where((e) => e.value.isNotEmpty)
        .map(
          (e) => TeacherGradeTeaching(
            gradeLevelId: e.key,
            subjectIds: e.value.toList()..sort(),
          ),
        )
        .toList();

    if (teachings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each grade needs at least one subject.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = TeacherProfile(
        employeeId: user.teacherProfile?.employeeId,
        department: user.teacherProfile?.department,
        teachingsByGrade: teachings,
      );
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'schoolId': user.schoolId ?? SchoolConfig.defaultSchoolId,
        'teacherProfile': profile.toMap(),
        'teacherSetupComplete': true,
        'teacherProfileSetupDeferred': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await auth.refreshUserProfile();
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completeLater() async {
    setState(() => _deferring = true);
    final ok = await context.read<AuthProvider>().deferTeacherProfileSetup();
    if (!mounted) return;
    setState(() => _deferring = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not continue. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final school = context.watch<SchoolAdminProvider>();
    final auth = context.watch<AuthProvider>();
    _loadExistingProfile(auth);
    final isEditing = auth.isTeacherProfileComplete;
    final showFirstLogin = widget.isFirstLogin && !isEditing;

    final pickable = _gradesAvailableToPick(school);
    GradeLevelModel? activeGrade;
    if (_activeGradeId != null) {
      for (final g in school.grades) {
        if (g.id == _activeGradeId) {
          activeGrade = g;
          break;
        }
      }
    }
    final subjectIdsForActive = _activeGradeId != null
        ? school.subjectIdsForGradeLevel(_activeGradeId!)
        : <String>[];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Update teaching profile'
              : showFirstLogin
                  ? 'Set up your teaching profile'
                  : 'Teacher profile',
        ),
        automaticallyImplyLeading: isEditing,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showFirstLogin) ...[
                Text(
                  'Welcome, ${auth.currentUser?.fullName ?? 'Teacher'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account was created without grade or subject details. '
                  'Add them here so the school can match you to classes and students.',
                  style: TextStyle(
                    height: 1.45,
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2894A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'You can teach more than one grade. For each grade, pick subjects '
                  'from that grade\'s class list (set by your admin). You can add '
                  'another grade anytime — lower or higher levels.',
                  style: TextStyle(height: 1.45, fontSize: 13),
                ),
              ),
              if (_byGrade.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Your grades',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ..._byGrade.entries.map((entry) {
                  final gradeName =
                      school.gradeNameForId(entry.key) ?? 'Grade';
                  final subs = entry.value
                      .map((id) => school.subjectNameForId(id) ?? '')
                      .where((n) => n.isNotEmpty)
                      .join(', ');
                  final isEditingThis = _activeGradeId == entry.key;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isEditingThis
                            ? AppTheme.primaryBlue
                            : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                      ),
                    ),
                    child: ListTile(
                      title: Text(gradeName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(subs, style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _editGrade(entry.key),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20, color: Colors.redAccent),
                            onPressed: () => _removeGrade(entry.key),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
              Text(
                _activeGradeId == null ? 'Add a grade level' : 'Subjects for ${activeGrade?.name ?? 'grade'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (school.grades.isEmpty)
                Text(
                  'No grades yet. Ask your school admin to add grades first.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                )
              else if (_activeGradeId == null) ...[
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Choose grade to add',
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: [
                    ...pickable.map(
                      (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
                    ),
                    ..._byGrade.keys.map((id) {
                      final g = school.grades.where((x) => x.id == id).firstOrNull;
                      if (g == null) return null;
                      return DropdownMenuItem(
                        value: g.id,
                        child: Text('${g.name} (edit)'),
                      );
                    }).whereType<DropdownMenuItem<String>>(),
                  ],
                  onChanged: (v) {
                    if (v != null) _selectGrade(v, school);
                  },
                ),
              ] else ...[
                if (subjectIdsForActive.isEmpty)
                  Text(
                    'This grade has no subjects set up yet. Ask admin to configure '
                    'the grade curriculum first.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjectIdsForActive.map((subjectId) {
                      final name =
                          school.subjectNameForId(subjectId) ?? 'Subject';
                      final selected = _draftSubjectIds.contains(subjectId);
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _draftSubjectIds.add(subjectId);
                            } else {
                              _draftSubjectIds.remove(subjectId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: subjectIdsForActive.isEmpty ? null : _commitActiveGrade,
                        child: const Text('Save this grade'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _activeGradeId = null;
                        _draftSubjectIds.clear();
                      }),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
              if (pickable.isNotEmpty && _activeGradeId == null && _byGrade.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${pickable.length} more grade(s) available to add above.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: 28),
              AuthPrimaryButton(
                label: _saving
                    ? 'Saving…'
                    : isEditing
                        ? 'Save profile'
                        : 'Save and open dashboard',
                onPressed: _saving || school.grades.isEmpty ? null : _save,
              ),
              if (showFirstLogin) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: (_saving || _deferring) ? null : _completeLater,
                    child: Text(
                      _deferring ? 'Opening dashboard…' : 'Complete later',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
