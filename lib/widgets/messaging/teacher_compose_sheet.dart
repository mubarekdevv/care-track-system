import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/teacher_attendance_provider.dart';

/// Teacher picks a parent from their class roster → opens chat.
class TeacherComposeSheet extends StatefulWidget {
  const TeacherComposeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const TeacherComposeSheet(),
    );
  }

  @override
  State<TeacherComposeSheet> createState() => _TeacherComposeSheetState();
}

class _TeacherComposeSheetState extends State<TeacherComposeSheet> {
  ParentContact? _contact;
  List<ParentContact> _contacts = [];
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final roster = context.read<TeacherAttendanceProvider>().roster;
    final contacts =
        await context.read<MessagingProvider>().parentContactsFromRoster(roster);
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final teacher = context.read<AuthProvider>().currentUser;
    final contact = _contact;
    if (teacher == null || contact == null) return;

    setState(() => _starting = true);
    final thread = await context.read<MessagingProvider>().ensureTeacherToParentThread(
          teacher: teacher,
          contact: contact,
        );
    if (!mounted) return;
    setState(() => _starting = false);

    if (thread == null) {
      final err = context.read<MessagingProvider>().errorMessage;
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message a parent',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only parents of students in your assigned classes are listed.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_contacts.isEmpty)
            const Text(
              'No students on your roster yet. Parents appear after enrollment.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            )
          else
            DropdownButtonFormField<ParentContact>(
              initialValue: _contact,
              decoration: const InputDecoration(
                labelText: 'Parent',
                border: OutlineInputBorder(),
              ),
              items: _contacts
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.parentName} (${c.subtitle})'),
                    ),
                  )
                  .toList(),
              onChanged: (c) => setState(() => _contact = c),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _starting || _contact == null ? null : _start,
              child: _starting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Open conversation'),
            ),
          ),
        ],
      ),
    );
  }
}
