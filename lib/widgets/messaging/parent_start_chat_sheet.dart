import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/child_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/messaging_provider.dart';

/// Parent picks child → teacher or assigned doctor → opens chat.
class ParentStartChatSheet extends StatefulWidget {
  const ParentStartChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ParentStartChatSheet(),
    );
  }

  @override
  State<ParentStartChatSheet> createState() => _ParentStartChatSheetState();
}

class _ParentStartChatSheetState extends State<ParentStartChatSheet> {
  _ChatTarget _target = _ChatTarget.teacher;
  ChildModel? _child;
  UserModel? _contact;
  List<UserModel> _contacts = [];
  bool _loadingContacts = false;
  bool _starting = false;

  Future<void> _loadContacts(ChildModel child) async {
    setState(() {
      _child = child;
      _contact = null;
      _loadingContacts = true;
      _contacts = [];
    });

    final messaging = context.read<MessagingProvider>();
    final list = _target == _ChatTarget.teacher
        ? await messaging.teachersForChild(child)
        : await messaging.assignedDoctorsForChild(child);

    if (!mounted) return;
    setState(() {
      _contacts = list;
      _loadingContacts = false;
    });
  }

  Future<void> _start() async {
    final user = context.read<AuthProvider>().currentUser;
    final child = _child;
    final contact = _contact;
    if (user == null || child == null || contact == null) return;

    setState(() => _starting = true);
    final messaging = context.read<MessagingProvider>();
    final thread = _target == _ChatTarget.teacher
        ? await messaging.ensureThread(
            parentId: user.uid,
            parentName: user.fullName,
            teacher: contact,
            child: child,
          )
        : await messaging.ensureDoctorParentThread(
            parentId: user.uid,
            parentName: user.fullName,
            doctor: contact,
            child: child,
            specialtyLabel: 'School clinic',
          );

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
    final children = context.watch<ChildProvider>().children;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start a conversation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Message teachers assigned to your child\'s class or doctors assigned for health follow-up.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_ChatTarget>(
            segments: const [
              ButtonSegment(
                value: _ChatTarget.teacher,
                label: Text('Teacher'),
                icon: Icon(Icons.school_outlined, size: 18),
              ),
              ButtonSegment(
                value: _ChatTarget.doctor,
                label: Text('Doctor'),
                icon: Icon(Icons.medical_services_outlined, size: 18),
              ),
            ],
            selected: {_target},
            onSelectionChanged: (values) {
              setState(() => _target = values.first);
              if (_child != null) _loadContacts(_child!);
            },
          ),
          const SizedBox(height: 16),
          if (children.isEmpty)
            const Text('Add a child profile first.')
          else ...[
            DropdownButtonFormField<ChildModel>(
              initialValue: _child,
              decoration: const InputDecoration(
                labelText: 'Your child',
                border: OutlineInputBorder(),
              ),
              items: children
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (c) {
                if (c != null) _loadContacts(c);
              },
            ),
            const SizedBox(height: 12),
            if (_child != null &&
                _target == _ChatTarget.teacher &&
                _child!.classRoomId == null)
              Text(
                'Enroll ${_child!.name} in a grade before messaging teachers.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              )
            else if (_child != null &&
                _target == _ChatTarget.doctor &&
                _child!.usesPrivateDoctor)
              Text(
                '${_child!.name} uses a private doctor — school doctor messaging is not available.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              )
            else if (_loadingContacts)
              const LinearProgressIndicator(minHeight: 2)
            else if (_child != null && _contacts.isEmpty)
              Text(
                _target == _ChatTarget.teacher
                    ? 'No teachers assigned to this class yet. Ask the school admin.'
                    : 'No school doctor assigned yet. Enable health follow-up or wait for admin assignment.',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              )
            else if (_contacts.isNotEmpty)
              DropdownButtonFormField<UserModel>(
                initialValue: _contact,
                decoration: InputDecoration(
                  labelText: _target == _ChatTarget.teacher ? 'Teacher' : 'Doctor',
                  border: const OutlineInputBorder(),
                ),
                items: _contacts
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.fullName)))
                    .toList(),
                onChanged: (t) => setState(() => _contact = t),
              ),
          ],
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

enum _ChatTarget { teacher, doctor }
