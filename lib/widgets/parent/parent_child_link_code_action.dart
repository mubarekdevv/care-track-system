import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/school_config.dart';
import '../../data/firestore/firestore_family_repository.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import 'link_code_dialog.dart';

/// Shows the 6-digit family link code for a child (parent can open anytime).
class ParentChildLinkCodeAction {
  ParentChildLinkCodeAction._();

  static Future<void> show(BuildContext context, ChildModel child) async {
    final parent = context.read<AuthProvider>().currentUser;
    if (parent == null) return;

    final repo = FirestoreFamilyRepository();
    var code = child.linkCode;
    if (code == null || code.length != 6) {
      code = await repo.getLinkCodeForStudent(child.id);
    }
    code ??= await repo.ensureLinkCodeForStudent(
      studentId: child.id,
      schoolId: child.schoolId.isNotEmpty ? child.schoolId : SchoolConfig.defaultSchoolId,
      createdByUid: parent.uid,
      studentName: child.name,
    );

    final linked = child.isAccountLinked;
    if (!context.mounted) return;

    await LinkCodeDialog.show(
      context,
      title: linked ? 'Family link code (linked)' : 'Family link code',
      message: linked
          ? '${child.name} already connected their account. '
              'Keep this code if they sign in on a new device, or share with support.'
          : 'Share this code with ${child.name}. They choose "My parent already enrolled me" '
              'and enter the code using the exact same full name: ${child.name}.',
      linkCode: code,
      childName: child.name,
    );
  }
}

class ParentChildLinkCodeIconButton extends StatelessWidget {
  final ChildModel child;
  final Color? iconColor;

  const ParentChildLinkCodeIconButton({
    super.key,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'View link code',
      icon: Icon(Icons.pin_rounded, color: iconColor),
      onPressed: () => ParentChildLinkCodeAction.show(context, child),
    );
  }
}
