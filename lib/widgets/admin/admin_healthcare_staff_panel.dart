import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/health/health_concerns.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/school_admin_provider.dart';

/// Pending + linked healthcare accounts (parallel to teachers).
class AdminHealthcareStaffPanel extends StatelessWidget {
  const AdminHealthcareStaffPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(
          'Healthcare staff (${admin.healthcareStaff.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Doctors register as Healthcare, select services in their profile, then you link them here.',
          style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        if (admin.pendingHealthcare.isNotEmpty) ...[
          Text(
            'Pending link (${admin.pendingHealthcare.length})',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          ...admin.pendingHealthcare.map(
            (d) => _HealthcareTile(
              doctor: d,
              admin: admin,
              pending: true,
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () async {
            final n = await admin.linkAllHealthcareToSchool();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    n > 0
                        ? 'Linked $n healthcare account(s) to your school.'
                        : 'All healthcare accounts are already linked.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.link_rounded),
          label: const Text('Link healthcare staff to school'),
        ),
        const SizedBox(height: 12),
        if (admin.healthcareStaff.isEmpty)
          const Text(
            'No linked healthcare staff yet.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          )
        else
          ...admin.healthcareStaff.map(
            (d) => _HealthcareTile(doctor: d, admin: admin, pending: false),
          ),
      ],
    );
  }
}

class _HealthcareTile extends StatelessWidget {
  final UserModel doctor;
  final SchoolAdminProvider admin;
  final bool pending;

  const _HealthcareTile({
    required this.doctor,
    required this.admin,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final labels = (doctor.healthcareProfile?.specialtyIds ?? [])
        .map((id) => HealthConcerns.byId(id)?.label ?? id)
        .join(', ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
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
          backgroundColor: const Color(0xFFE2894A).withValues(alpha: 0.12),
          child: const Icon(Icons.medical_services_outlined,
              color: Color(0xFFE2894A), size: 20),
        ),
        title: Text(doctor.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          labels.isEmpty ? 'No services selected yet' : labels,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: pending
            ? FilledButton.tonal(
                onPressed: () async {
                  final ok = await admin.linkHealthcareToSchool(doctor.uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Linked ${doctor.fullName}.' : admin.error ?? 'Failed.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Link'),
              )
            : null,
      ),
    );
  }
}
