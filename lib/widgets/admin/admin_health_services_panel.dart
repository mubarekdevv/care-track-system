import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/health/health_concerns.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/school_admin_provider.dart';

/// Admin: choose which health services the school offers (parent + doctor pickers).
class AdminHealthServicesPanel extends StatefulWidget {
  const AdminHealthServicesPanel({super.key});

  @override
  State<AdminHealthServicesPanel> createState() => _AdminHealthServicesPanelState();
}

class _AdminHealthServicesPanelState extends State<AdminHealthServicesPanel> {
  late Set<String> _selected;
  bool _saving = false;
  String? _lastSchoolId;

  void _syncFromAdmin(SchoolAdminProvider admin) {
    if (_lastSchoolId == admin.schoolId && _selected.isNotEmpty) return;
    _lastSchoolId = admin.schoolId;
    final enabled = admin.enabledHealthSpecialtyIds;
    _selected = enabled.isEmpty
        ? HealthConcerns.catalog.map((c) => c.id).toSet()
        : enabled.toSet();
  }

  Future<void> _save(SchoolAdminProvider admin) async {
    setState(() => _saving = true);
    final ok = await admin.updateEnabledHealthSpecialties(_selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Health services updated for parents and doctors.'
              : admin.error ?? 'Could not save.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();
    _syncFromAdmin(admin);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_outlined,
                  color: const Color(0xFFE2894A).withValues(alpha: 0.9)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'School health services',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable the health areas parents can request and doctors can register for. '
            'When no doctor exists for a selected area, you resolve requests like missing teachers.',
            style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: HealthConcerns.catalog.map((concern) {
              final selected = _selected.contains(concern.id);
              return FilterChip(
                label: Text(concern.label, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selected.add(concern.id);
                    } else {
                      _selected.remove(concern.id);
                      if (_selected.isEmpty) {
                        _selected.add(HealthConcerns.none);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : () => _save(admin),
              child: Text(_saving ? 'Saving…' : 'Save services'),
            ),
          ),
        ],
      ),
    );
  }
}
