import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/child_model.dart';
import '../../models/message_thread_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/healthcare_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../services/database_service.dart';

enum _HealthcareComposeTarget { parent, student }

/// Doctor picks a patient → messages parent and/or linked student.
class HealthcareComposeSheet extends StatefulWidget {
  const HealthcareComposeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const HealthcareComposeSheet(),
    );
  }

  @override
  State<HealthcareComposeSheet> createState() => _HealthcareComposeSheetState();
}

class _HealthcareComposeSheetState extends State<HealthcareComposeSheet> {
  ChildModel? _patient;
  _HealthcareComposeTarget _target = _HealthcareComposeTarget.parent;
  bool _starting = false;

  Future<void> _start() async {
    final doctor = context.read<AuthProvider>().currentUser;
    final patient = _patient;
    if (doctor == null || patient == null) return;

    setState(() => _starting = true);
    final messaging = context.read<MessagingProvider>();
    MessageThread? thread;
    if (_target == _HealthcareComposeTarget.parent) {
      final parentUser = await DatabaseService().getUserById(patient.parentId);
      thread = await messaging.ensureHealthcareToParentThread(
        doctor: doctor,
        contact: HealthcareParentContact(
          parentId: patient.parentId,
          parentName: parentUser?.fullName ?? 'Parent',
          studentId: patient.id,
          studentName: patient.name,
        ),
      );
    } else {
      thread = await messaging.ensureHealthcareToStudentThread(
        doctor: doctor,
        child: patient,
      );
    }

    if (!mounted) return;
    setState(() => _starting = false);

    if (thread == null) {
      final err = messaging.errorMessage;
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
    final patients = context.watch<HealthcareProvider>().patients;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final canMessageStudent =
        _patient?.studentUserId != null && _patient!.studentUserId!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message about a patient',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contact the parent or the student (after they link their login code).',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (patients.isEmpty)
            const Text(
              'No assigned patients yet. Students appear after health follow-up and doctor assignment.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            )
          else ...[
            DropdownButtonFormField<ChildModel>(
              initialValue: _patient,
              decoration: const InputDecoration(
                labelText: 'Patient',
                border: OutlineInputBorder(),
              ),
              items: patients
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (p) => setState(() => _patient = p),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_HealthcareComposeTarget>(
              segments: const [
                ButtonSegment(
                  value: _HealthcareComposeTarget.parent,
                  label: Text('Parent'),
                  icon: Icon(Icons.family_restroom_outlined, size: 18),
                ),
                ButtonSegment(
                  value: _HealthcareComposeTarget.student,
                  label: Text('Student'),
                  icon: Icon(Icons.school_outlined, size: 18),
                ),
              ],
              selected: {_target},
              onSelectionChanged: canMessageStudent
                  ? (values) => setState(() => _target = values.first)
                  : null,
            ),
            if (_target == _HealthcareComposeTarget.student && !canMessageStudent)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_patient?.name ?? 'This student'} has not linked their student app yet.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _starting || _patient == null ? null : _start,
              child: _starting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _target == _HealthcareComposeTarget.parent
                          ? 'Message parent'
                          : 'Message student',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
