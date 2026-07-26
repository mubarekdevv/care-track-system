import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/health/health_concerns.dart';
import '../../core/theme/app_theme.dart';
import '../../data/firestore/firestore_doctor_matching_repository.dart';
import '../../models/doctor_matching_models.dart';
import '../../models/user_model.dart';
import '../../providers/school_admin_provider.dart';

/// Admin view: parents waiting for a healthcare professional by specialty.
class AdminDoctorRequestsPanel extends StatelessWidget {
  const AdminDoctorRequestsPanel({super.key});

  Future<void> _assignSpecialtyToDoctor(
    BuildContext context, {
    required DoctorMatchRequest request,
    required UserModel doctor,
  }) async {
    final repo = FirestoreDoctorMatchingRepository();
    final existing = doctor.healthcareProfile?.specialtyIds ?? [];
    if (existing.contains(request.specialtyId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor already has this specialty.')),
      );
      return;
    }
    final updated = [...existing, request.specialtyId];
    await repo.updateHealthcareSpecialties(
      doctorUserId: doctor.uid,
      specialtyIds: updated,
      schoolId: request.schoolId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${request.specialtyLabel} to ${doctor.fullName}. Parent was notified.',
          ),
        ),
      );
    }
  }

  Future<void> _pickDoctor(BuildContext context, DoctorMatchRequest request) async {
    final repo = FirestoreDoctorMatchingRepository();
    final snap = await repo.findDoctorsForSpecialty(
      schoolId: request.schoolId,
      specialtyId: request.specialtyId,
    );

    final allHealthcare = await _loadAllHealthcare(request.schoolId);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign ${request.specialtyLabel} doctor',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'For ${request.studentName}. Pick a healthcare account and add this specialty.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                if (allHealthcare.isEmpty)
                  const Text('No healthcare accounts linked to this school yet.')
                else
                  ...allHealthcare.map(
                    (d) => ListTile(
                      leading: const Icon(Icons.medical_services_outlined),
                      title: Text(d.fullName),
                      subtitle: Text(() {
                        final labels = (d.healthcareProfile?.specialtyIds ?? [])
                            .map((id) => HealthConcerns.byId(id)?.label ?? id)
                            .join(', ');
                        return labels.isEmpty ? 'No specialties set' : labels;
                      }()),
                      trailing: FilledButton.tonal(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _assignSpecialtyToDoctor(
                            context,
                            request: request,
                            doctor: d,
                          );
                        },
                        child: const Text('Add specialty'),
                      ),
                    ),
                  ),
                if (snap.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Already qualified:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...snap.map(
                    (d) => ListTile(
                      dense: true,
                      title: Text(d.fullName),
                      subtitle: const Text('Parents can assign from Health tab'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<UserModel>> _loadAllHealthcare(String schoolId) async {
    return FirestoreDoctorMatchingRepository().listHealthcareStaff(schoolId);
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<SchoolAdminProvider>().schoolId;
    final repo = FirestoreDoctorMatchingRepository();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<DoctorMatchRequest>>(
      stream: repo.watchPendingRequestsForSchool(schoolId),
      builder: (context, snap) {
        final requests = snap.data ?? [];
        if (requests.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.all(16),
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
                  Icon(Icons.medical_information_outlined, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${requests.length} parent request(s) for doctors',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...requests.take(5).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${r.studentName} needs ${r.specialtyLabel}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickDoctor(context, r),
                        child: const Text('Resolve'),
                      ),
                    ],
                  ),
                ),
              ),
              if (requests.length > 5)
                Text('+ ${requests.length - 5} more', style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}
