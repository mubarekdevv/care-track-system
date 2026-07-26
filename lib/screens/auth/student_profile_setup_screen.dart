import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/school_config.dart';
import '../../core/constants/routes.dart';
import '../../core/domain/domain_enums.dart';
import '../../core/navigation/kidcare_logout.dart';
import '../../core/theme/app_theme.dart';
import '../../data/firestore/firestore_family_repository.dart';
import '../../data/firestore/firestore_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/common/kidcare_form_field.dart';

enum _StudentSetupStep { choosePath, linkWithParent, createNew }

/// Student completes profile or links to a parent-created record via code.
class StudentProfileSetupScreen extends StatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  State<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkCodeController = TextEditingController();

  _StudentSetupStep _step = _StudentSetupStep.choosePath;
  DateTime? _dob;
  Gender? _gender;
  String? _gradeId;
  String? _expectedNameForCode;
  bool _saving = false;

  @override
  void dispose() {
    _linkCodeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCodeHint() async {
    final code = _linkCodeController.text.trim();
    if (code.length != 6) {
      setState(() => _expectedNameForCode = null);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.familyLinkCodes)
        .doc(code)
        .get();
    if (!mounted) return;
    setState(() {
      _expectedNameForCode =
          doc.data()?['studentName'] as String? ?? doc.data()?['studentId'] as String?;
    });
  }

  Future<void> _finishToHome() async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _submitLinkWithParent() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final code = _linkCodeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code from your parent.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final studentId = await FirestoreFamilyRepository().linkStudentAuthWithCode(
        code: code,
        studentUserId: user.uid,
        studentEmail: user.email,
        studentFullName: user.fullName,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'linkedStudentId': studentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await auth.refreshUserProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your login is now connected to your school profile. '
            'Your parent could already see your enrollment — linking lets YOU sign in and use the student app.',
          ),
          backgroundColor: AppTheme.softGreen,
          duration: Duration(seconds: 5),
        ),
      );
      await _finishToHome();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitCreateNew() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null || _gender == null || _gradeId == null) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final studentId = FirebaseFirestore.instance.collection('children').doc().id;
      final schoolId = user.schoolId ?? SchoolConfig.defaultSchoolId;
      final name = user.fullName;

      await FirebaseFirestore.instance.collection('children').doc(studentId).set(
        FirestoreHelpers.withTimestamps(
          {
            'schemaVersion': SchoolConfig.currentStudentSchemaVersion,
            'schoolId': schoolId,
            'parentId': '',
            'fullName': name,
            'name': name,
            'dateOfBirth': Timestamp.fromDate(_dob!),
            'gender': _gender!.id,
            'gradeLevelId': _gradeId,
            'imageUrl': '',
            'accountMode': StudentAccountMode.selfLogin.id,
            'studentUserId': user.uid,
            'studentEmail': user.email,
            'healthModuleEnabled': false,
          },
          isCreate: true,
        ),
      );

      await FirestoreFamilyRepository().createLinkCodeForStudent(
        studentId: studentId,
        schoolId: schoolId,
        createdByUid: user.uid,
        studentName: name,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'linkedStudentId': studentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await auth.refreshUserProfile();

      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.linkParent);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Connect your profile'),
        leading: _step == _StudentSetupStep.choosePath
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _saving
                    ? null
                    : () => setState(() => _step = _StudentSetupStep.choosePath),
              ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => kidCareLogout(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null)
                Text(
                  'Signed in as ${user.fullName}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _step == _StudentSetupStep.choosePath
                    ? 'How were you added to the school?'
                    : _step == _StudentSetupStep.linkWithParent
                        ? 'Enter your parent’s link code'
                        : 'Create a new student profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              if (_step == _StudentSetupStep.choosePath) _buildChoosePath(isDark),
              if (_step == _StudentSetupStep.linkWithParent) _buildLinkForm(isDark),
              if (_step == _StudentSetupStep.createNew) _buildCreateForm(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoosePath(bool isDark) {
    return Column(
      children: [
        _PathCard(
          isDark: isDark,
          icon: Icons.link_rounded,
          color: AppTheme.primaryBlue,
          title: 'My parent already enrolled me',
          subtitle:
              'Use the 6-digit code your parent received (for example 563617). '
              'You will not fill grade/details again.',
          onTap: () => setState(() => _step = _StudentSetupStep.linkWithParent),
        ),
        const SizedBox(height: 14),
        _PathCard(
          isDark: isDark,
          icon: Icons.person_add_alt_1_rounded,
          color: AppTheme.softGreen,
          title: 'I am registering on my own',
          subtitle:
              'Only choose this if your parent has not added you yet. '
              'You will enter your school details and get a code for your parent.',
          onTap: () => setState(() => _step = _StudentSetupStep.createNew),
        ),
      ],
    );
  }

  Widget _buildLinkForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Important: register with the same full name your parent used when they added you.',
            style: TextStyle(height: 1.4, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        KidCareFormField(
          controller: _linkCodeController,
          label: '6-digit parent code',
          hint: '563617',
          prefixIcon: Icons.pin_rounded,
          maxLength: 6,
          keyboardType: TextInputType.number,
          onChanged: (_) => _lookupCodeHint(),
        ),
        if (_expectedNameForCode != null && _expectedNameForCode!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'This code is for: $_expectedNameForCode',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: _saving ? 'Linking…' : 'Link to my parent',
          onPressed: _saving ? null : _submitLinkWithParent,
        ),
      ],
    );
  }

  Widget _buildCreateForm(bool isDark) {
    final grades = context.watch<SchoolAdminProvider>().grades;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          KidCarePickerTile(
            label: 'Date of birth',
            value: _dob == null
                ? 'Select date'
                : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
            icon: Icons.event_rounded,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                firstDate: DateTime(1995),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dob = picked);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Gender>(
            initialValue: _gender,
            items: Gender.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.id)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v),
            decoration: InputDecoration(
              labelText: 'Gender',
              filled: true,
              fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gradeId,
            items: grades
                .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                .toList(),
            onChanged: (v) => setState(() => _gradeId = v),
            decoration: InputDecoration(
              labelText: 'Grade level',
              filled: true,
              fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: _saving ? 'Saving…' : 'Continue',
            onPressed: _saving ? null : _submitCreateNew,
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PathCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
