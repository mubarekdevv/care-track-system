import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/school_config.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/firestore/firestore_family_repository.dart';
import '../../providers/auth_provider.dart';
import '../parent/link_code_dialog.dart';

/// Student shows their 6-digit code for a parent to link (same idea as parent view).
class StudentParentLinkCodeAction {
  StudentParentLinkCodeAction._();

  static Future<void> show(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final studentId = user?.linkedStudentId;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete your student profile first.'),
        ),
      );
      return;
    }

    final repo = FirestoreFamilyRepository();
    var code = await repo.getLinkCodeForStudent(studentId);
    code ??= await repo.ensureLinkCodeForStudent(
      studentId: studentId,
      schoolId: user?.schoolId ?? SchoolConfig.defaultSchoolId,
      createdByUid: user!.uid,
      studentName: user.fullName,
    );

    if (!context.mounted) return;

    await LinkCodeDialog.show(
      context,
      title: 'Code for your parent',
      message:
          'Ask your parent to sign in as Parent, open the menu, tap '
          '"Link with code", and enter this number. '
          'You stay signed in on your account.',
      linkCode: code,
      childName: user!.fullName,
      showEnrollmentNote: false,
    );
  }

  static void openFullScreen(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.linkParent);
  }
}

/// Opens the full connect-parent screen (same as after self-registration).
class StudentParentLinkCodeTile extends StatelessWidget {
  const StudentParentLinkCodeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
        child: const Icon(Icons.family_restroom_rounded, color: AppTheme.primaryBlue),
      ),
      title: const Text('My parent link code',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text(
        'Share your 6-digit code so your parent can connect to you',
        style: TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => StudentParentLinkCodeAction.openFullScreen(context),
    );
  }
}
