import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/school_config.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/firestore/firestore_family_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';

/// After self-registration — show the student's 6-digit code for their parent.
class LinkParentScreen extends StatefulWidget {
  const LinkParentScreen({super.key});

  @override
  State<LinkParentScreen> createState() => _LinkParentScreenState();
}

class _LinkParentScreenState extends State<LinkParentScreen> {
  String? _linkCode;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final user = context.read<AuthProvider>().currentUser;
    final studentId = user?.linkedStudentId;
    if (studentId == null || studentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Complete your student profile first.';
      });
      return;
    }

    try {
      final repo = FirestoreFamilyRepository();
      var code = await repo.getLinkCodeForStudent(studentId);
      code ??= await repo.ensureLinkCodeForStudent(
        studentId: studentId,
        schoolId: user!.schoolId ?? SchoolConfig.defaultSchoolId,
        createdByUid: user.uid,
        studentName: user.fullName,
      );
      if (!mounted) return;
      setState(() {
        _linkCode = code;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _goToDashboard() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.roleSelection, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkCode = _linkCode ?? '------';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Connect a parent'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _goToDashboard,
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        AuthPrimaryButton(
                          label: 'Back to dashboard',
                          onPressed: _goToDashboard,
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share this code with your parent',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your parent signs in as Parent, opens the menu, taps '
                          '"Link with code", and enters this number. '
                          'You can open this screen anytime from Profile or the menu.',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            _formatCode(linkCode),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 10,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: linkCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy code'),
                        ),
                        const Spacer(),
                        AuthPrimaryButton(
                          label: 'Continue to my dashboard',
                          onPressed: _goToDashboard,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length != 6) return code;
    return code.split('').join(' ');
  }
}
