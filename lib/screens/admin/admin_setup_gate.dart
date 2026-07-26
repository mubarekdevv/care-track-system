import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_branding.dart';
import '../../core/navigation/kidcare_logout.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_admin_provider.dart';

/// First logged-in user on a new deployment creates the school.
class FirstAdminSetupScreen extends StatefulWidget {
  const FirstAdminSetupScreen({super.key});

  @override
  State<FirstAdminSetupScreen> createState() => _FirstAdminSetupScreenState();
}

class _FirstAdminSetupScreenState extends State<FirstAdminSetupScreen> {
  final _nameController = TextEditingController();
  bool _busy = false;
  bool _confirmAdmin = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final admin = context.read<SchoolAdminProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final ok = await admin.claimFirstAdmin(schoolName: name, user: user);
    if (!mounted) return;

    if (ok) {
      await auth.refreshUserProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(admin.error ?? 'Setup failed')),
      );
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : () => kidCareLogout(context),
                  child: const Text('Sign out'),
                ),
              ),
              const Spacer(),
              Icon(Icons.apartment_rounded,
                  size: 56, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
              const SizedBox(height: 20),
              Text(
                'Set up your school',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome to ${AppBranding.name}. You\'re the first user — '
                'create your school profile to get started.\n\n'
                'Important: this account becomes Admin. After setup, open the Admin '
                'dashboard and tap "Load Grades 1–5 catalog" so parents see all grades '
                'and teachers when enrolling children.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'School or childcare name',
                  hintText: 'e.g. Sunrise Elementary',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _confirmAdmin,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _confirmAdmin = value == true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I understand this account will be set as Admin for school setup.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: (_busy || !_confirmAdmin) ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create school & continue'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Other users wait until an admin finishes school setup.
class SchoolNotReadyScreen extends StatelessWidget {
  const SchoolNotReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 48, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              const Text(
                'School setup in progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your administrator is still configuring grades and classes. '
                'Please check back soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => kidCareLogout(context),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
