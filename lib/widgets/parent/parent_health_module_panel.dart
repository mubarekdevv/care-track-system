import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/school_config.dart';
import '../../core/constants/routes.dart';
import '../../core/health/health_concerns.dart';
import '../../core/theme/app_theme.dart';
import '../../data/firestore/firestore_doctor_matching_repository.dart';
import '../../data/firestore/firestore_health_repository.dart';
import '../../models/child_model.dart';
import '../../models/doctor_matching_models.dart';
import '../../models/health_profile_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/messaging_provider.dart';

/// Parent health tab: opt-in, doctor matching, assignments, and messaging.
class ParentHealthModulePanel extends StatelessWidget {
  final ChildModel child;
  final bool isDark;

  const ParentHealthModulePanel({
    super.key,
    required this.child,
    required this.isDark,
  });

  Future<void> _toggleAccess(BuildContext context, bool value) async {
    final parentId = context.read<AuthProvider>().currentUser?.uid;
    if (parentId == null) return;

    final ok = await context.read<ChildProvider>().setHealthModuleEnabled(
          childId: child.id,
          parentId: parentId,
          enabled: value,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (value
                  ? 'School healthcare staff can support ${child.name}.'
                  : 'Healthcare access revoked for ${child.name}.')
              : 'Could not update health settings.',
        ),
      ),
    );
  }

  Future<void> _assignDoctor(
    BuildContext context,
    MatchedDoctor doctor,
    String specialtyId,
  ) async {
    final parentId = context.read<AuthProvider>().currentUser?.uid;
    if (parentId == null) return;

    final ok = await context.read<ChildProvider>().assignDoctorToChild(
          childId: child.id,
          parentId: parentId,
          doctorId: doctor.doctorId,
          specialtyId: specialtyId,
          schoolId: child.schoolId.isNotEmpty
              ? child.schoolId
              : SchoolConfig.defaultSchoolId,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${doctor.fullName} is now assigned to ${child.name}.'
              : context.read<ChildProvider>().errorMessage ?? 'Assignment failed.',
        ),
      ),
    );
  }

  Future<void> _openDoctorChat(
    BuildContext context,
    UserModel doctor,
    String specialtyLabel,
  ) async {
    final auth = context.read<AuthProvider>();
    final parent = auth.currentUser;
    if (parent == null) return;

    final thread = await context.read<MessagingProvider>().ensureDoctorParentThread(
          parentId: parent.uid,
          parentName: parent.fullName,
          doctor: doctor,
          child: child,
          specialtyLabel: specialtyLabel,
        );
    if (!context.mounted || thread == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<MessagingProvider>().errorMessage ??
                  'Could not start conversation.',
            ),
          ),
        );
      }
      return;
    }
    Navigator.pushNamed(context, AppRoutes.chat, arguments: thread);
  }

  @override
  Widget build(BuildContext context) {
    final matchingRepo = FirestoreDoctorMatchingRepository();
    final healthRepo = FirestoreHealthRepository();
    final concernLabels = HealthConcerns.labelsForIds(child.healthConcernIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          isDark: isDark,
          title: 'Health follow-up needs',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (child.usesPrivateDoctor)
                const Text(
                  'Using a private doctor outside school — no school doctor assignment needed.',
                  style: TextStyle(fontSize: 12, height: 1.45),
                )
              else if (child.healthConcernIds.isEmpty)
                Text(
                  'No follow-up areas selected at enrollment. Edit from re-enrollment or ask admin.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: child.healthConcernIds
                      .map((id) {
                        final opt = HealthConcerns.byId(id);
                        return Chip(
                          avatar: Icon(opt?.icon ?? Icons.medical_services_outlined, size: 16),
                          label: Text(opt?.label ?? id, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.softGreen.withValues(alpha: 0.12),
                          side: BorderSide.none,
                        );
                      })
                      .toList(),
                ),
              const SizedBox(height: 8),
              Text(
                concernLabels,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!child.usesPrivateDoctor) ...[
          StreamBuilder<List<DoctorMatchRequest>>(
            stream: matchingRepo.watchPendingRequestsForStudent(child.id),
            builder: (context, snap) {
              final pending = snap.data ?? [];
              if (pending.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  _SectionCard(
                    isDark: isDark,
                    title: 'Waiting for school doctor',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pending
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.hourglass_top_rounded,
                                      size: 18, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Admin notified: no ${r.specialtyLabel} doctor yet for ${child.name}.',
                                      style: const TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            },
          ),
          StreamBuilder<List<StudentDoctorAssignment>>(
            stream: matchingRepo.watchAssignmentsForStudent(child.id),
            builder: (context, assignSnap) {
              final assignments = assignSnap.data ?? [];
              return FutureBuilder<List<MatchedDoctor>>(
                future: _loadAvailableDoctors(matchingRepo, child),
                builder: (context, doctorSnap) {
                  final doctors = doctorSnap.data ?? [];
                  return _SectionCard(
                    isDark: isDark,
                    title: 'Assigned & available doctors',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (assignments.isEmpty && doctors.isEmpty)
                          Text(
                            'No school doctor matched yet for the selected health needs.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                            ),
                          ),
                        ...assignments.map(
                          (a) => _DoctorRow(
                            name: a.doctorName,
                            subtitle: a.specialtyLabel,
                            assigned: true,
                            onMessage: () async {
                              final user = await matchingRepo.getUser(a.doctorId);
                              if (user != null && context.mounted) {
                                await _openDoctorChat(context, user, a.specialtyLabel);
                              }
                            },
                          ),
                        ),
                        ...child.healthConcernIds.where((id) {
                          return !assignments.any((a) => a.specialtyId == id);
                        }).expand((specialtyId) {
                          final matched = doctors
                              .where((d) => d.specialtyIds.contains(specialtyId))
                              .toList();
                          return matched.map(
                            (d) => _DoctorRow(
                              name: d.fullName,
                              subtitle:
                                  '${HealthConcerns.byId(specialtyId)?.label ?? specialtyId}${d.clinicName != null ? ' • ${d.clinicName}' : ''}',
                              assigned: false,
                              onAssign: () => _assignDoctor(context, d, specialtyId),
                              onMessage: assignments.any((a) => a.doctorId == d.doctorId)
                                  ? () async {
                                      final user = await matchingRepo.getUser(d.doctorId);
                                      if (user != null && context.mounted) {
                                        await _openDoctorChat(
                                          context,
                                          user,
                                          HealthConcerns.byId(specialtyId)?.label ?? '',
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),
        ],
        _SectionCard(
          isDark: isDark,
          title: 'Share profile with school clinic',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Optional: let school healthcare staff view growth notes and follow-up history.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: child.healthModuleEnabled,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.softGreen;
                  }
                  return null;
                }),
                title: Text(
                  child.healthModuleEnabled ? 'Clinic access on' : 'Clinic access off',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                onChanged: (v) => _toggleAccess(context, v),
              ),
            ],
          ),
        ),
        if (child.healthModuleEnabled) ...[
          const SizedBox(height: 14),
          StreamBuilder<HealthProfileModel?>(
            stream: healthRepo.watchHealthProfile(child.id),
            builder: (context, snap) {
              final profile = snap.data;
              if (profile == null) return const SizedBox.shrink();
              return _SectionCard(
                isDark: isDark,
                title: 'Clinic record summary',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.medicalConditions.isNotEmpty)
                      Text('Conditions: ${profile.medicalConditions.join(', ')}',
                          style: const TextStyle(fontSize: 12)),
                    if (profile.disabilities.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Support needs: ${profile.disabilities.join(', ')}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                    if (profile.latestHeight != null || profile.latestWeight != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Growth: ${profile.latestHeight?.toStringAsFixed(1) ?? '—'} cm • '
                        '${profile.latestWeight?.toStringAsFixed(1) ?? '—'} kg',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<List<MatchedDoctor>> _loadAvailableDoctors(
    FirestoreDoctorMatchingRepository repo,
    ChildModel child,
  ) async {
    final schoolId =
        child.schoolId.isNotEmpty ? child.schoolId : SchoolConfig.defaultSchoolId;
    final all = <MatchedDoctor>[];
    final seen = <String>{};
    for (final id in child.healthConcernIds) {
      final list = await repo.findDoctorsForSpecialty(
        schoolId: schoolId,
        specialtyId: id,
      );
      for (final d in list) {
        if (seen.add(d.doctorId)) all.add(d);
      }
    }
    return all;
  }
}

class _DoctorRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool assigned;
  final VoidCallback? onAssign;
  final VoidCallback? onMessage;

  const _DoctorRow({
    required this.name,
    required this.subtitle,
    required this.assigned,
    this.onAssign,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            assigned ? Icons.check_circle_rounded : Icons.person_search_rounded,
            size: 20,
            color: assigned ? AppTheme.softGreen : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (!assigned && onAssign != null)
            TextButton(onPressed: onAssign, child: const Text('Assign')),
          if (onMessage != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              tooltip: 'Message doctor',
              onPressed: onMessage,
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
