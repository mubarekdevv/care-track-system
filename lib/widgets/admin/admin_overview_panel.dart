import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_branding.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/school_admin_provider.dart';
import 'admin_doctor_requests_panel.dart';
import 'admin_grade_range_dialogs.dart';
import 'admin_health_services_panel.dart';

class AdminOverviewPanel extends StatelessWidget {
  final String? schoolName;
  final String? userName;
  final VoidCallback onEditSchoolName;

  const AdminOverviewPanel({
    super.key,
    this.schoolName,
    this.userName,
    required this.onEditSchoolName,
  });

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade800 : AppTheme.inputBorder;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _HeroCard(
          userName: userName,
          schoolName: schoolName,
          maxGradeLabel: admin.maxGradeLabel,
          onEditSchoolName: onEditSchoolName,
        ),
        const SizedBox(height: 16),
        const AdminDoctorRequestsPanel(),
        const AdminHealthServicesPanel(),
        const SizedBox(height: 20),
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _MetricTile(
              label: 'Grades',
              value: '${admin.grades.length}',
              detail: admin.grades.isEmpty
                  ? 'Set range on Home'
                  : '${admin.gradesReadyCount} ready · ${admin.gradesPendingTeachersCount} pending',
              icon: Icons.layers_rounded,
              color: AppTheme.primaryBlue,
            ),
            _MetricTile(
              label: 'Max level',
              value: admin.effectiveMaxCatalogGradeLevel > 0
                  ? 'G${admin.effectiveMaxCatalogGradeLevel}'
                  : '—',
              detail: admin.effectiveMaxCatalogGradeLevel > 0
                  ? 'Add menu: Grade 1–${admin.effectiveMaxCatalogGradeLevel}'
                  : 'Load curriculum',
              icon: Icons.stairs_rounded,
              color: const Color(0xFF5C6BC0),
            ),
            _MetricTile(
              label: 'Ready',
              value: '${admin.gradesReadyCount}',
              detail: 'Parents can enroll',
              icon: Icons.verified_rounded,
              color: AppTheme.softGreen,
            ),
            _MetricTile(
              label: 'Teachers',
              value: '${admin.teachers.length}',
              detail: '${admin.subjects.length} subjects',
              icon: Icons.groups_rounded,
              color: const Color(0xFFE2894A),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
                    const SizedBox(width: 10),
                    const Text(
                      'Grade range',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  admin.effectiveMaxCatalogGradeLevel > 0
                      ? 'Your school uses standard grades through ${admin.maxGradeLabel}. '
                          'The Grades tab only offers levels up to that maximum.'
                      : 'Load the starter curriculum to set how many grade levels your school uses.',
                  style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: admin.isBusy
                            ? null
                            : () => showLoadStarterCurriculumDialog(context),
                        icon: const Icon(Icons.auto_stories_rounded, size: 20),
                        label: Text(admin.isBusy ? 'Working…' : 'Load curriculum'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: admin.isBusy
                            ? null
                            : () => showChangeMaxGradeDialog(context),
                        icon: const Icon(Icons.unfold_more_rounded, size: 20),
                        label: const Text('Change max'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Setup checklist',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                _CheckRow(done: admin.effectiveMaxCatalogGradeLevel > 0, label: 'Grade range configured'),
                _CheckRow(done: admin.grades.isNotEmpty, label: 'At least one grade created'),
                _CheckRow(
                  done: admin.gradesReadyCount > 0,
                  label: 'At least one grade ready for parents',
                ),
                _CheckRow(done: admin.teachers.isNotEmpty, label: 'Teachers linked to school'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String? userName;
  final String? schoolName;
  final String maxGradeLabel;
  final VoidCallback onEditSchoolName;

  const _HeroCard({
    this.userName,
    this.schoolName,
    required this.maxGradeLabel,
    required this.onEditSchoolName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A5C), AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${userName ?? 'Admin'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schoolName ?? AppBranding.name,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.stairs_rounded, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Highest grade: $maxGradeLabel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEditSchoolName,
            icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.white70),
            label: const Text(
              'Edit school name',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, height: 1.25, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final bool done;
  final String label;

  const _CheckRow({required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: done ? AppTheme.softGreen : AppTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
