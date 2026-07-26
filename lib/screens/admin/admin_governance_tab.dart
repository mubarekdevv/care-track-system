import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/kidcare_logout.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_admin_provider.dart';

/// Promote/demote admins and transfer main admin role.
class AdminGovernanceTab extends StatefulWidget {
  const AdminGovernanceTab({super.key});

  @override
  State<AdminGovernanceTab> createState() => _AdminGovernanceTabState();
}

class _AdminGovernanceTabState extends State<AdminGovernanceTab> {
  final _emailController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        await context.read<SchoolAdminProvider>().ensurePrimaryAdminRecord(uid);
      }
    });
  }

  Future<void> _promote(SchoolAdminProvider admin) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    final ok = await admin.promoteUserToAdminByEmail(email);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User promoted to admin.')),
      );
    } else if (admin.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(admin.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();
    final currentUid = context.watch<AuthProvider>().currentUser?.uid ?? '';
    final isPrimary = admin.isPrimaryAdmin(currentUid);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _GovInfoBanner(
          icon: Icons.admin_panel_settings_rounded,
          title: 'School administrators',
          body:
              'Admins manage grades, sections, teachers, and school settings. '
              'Promote trusted staff by their registered email. '
              'Admin is not available on public sign-up.',
        ),
        const SizedBox(height: 16),
        Text(
          'Add admin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _GovInputCard(
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Registered email',
                  hintText: 'teacher@school.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _promote(admin),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Promote to admin'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Current admins (${admin.admins.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (admin.admins.isEmpty)
          const _GovEmptyState(
            icon: Icons.shield_outlined,
            message: 'No admins found.',
          )
        else
          ...admin.admins.map(
            (a) => _AdminUserTile(
              user: a,
              isPrimary: admin.isPrimaryAdmin(a.uid),
              isSelf: a.uid == currentUid,
              onRemove: () => _confirmRemove(context, admin, a, currentUid),
            ),
          ),
        if (isPrimary && admin.admins.length > 1) ...[
          const SizedBox(height: 24),
          Text(
            'Transfer main admin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'The main admin can transfer ownership to another admin when handing off school management.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...admin.admins
              .where((a) => a.uid != currentUid)
              .map(
                (a) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(a.fullName),
                    subtitle: Text(a.email),
                    trailing: OutlinedButton(
                      onPressed: () => _confirmTransfer(context, admin, a, currentUid),
                      child: const Text('Make main'),
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    SchoolAdminProvider admin,
    UserModel target,
    String actingUid,
  ) async {
    final fallback = target.teacherProfile != null ? 'Teacher' : 'Parent';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove admin access?'),
        content: Text(
          'Remove admin role from ${target.fullName}? '
          'They will return to $fallback access.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final removed = await admin.removeAdminRole(
      target: target,
      actingAdminUid: actingUid,
    );
    if (!context.mounted) return;
    if (removed) {
      if (target.uid == actingUid) {
        await context.read<AuthProvider>().refreshUserProfile();
        if (!context.mounted) return;
        await kidCareLogout(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${target.fullName} is no longer an admin.')),
      );
    } else if (admin.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(admin.error!)),
      );
    }
  }

  Future<void> _confirmTransfer(
    BuildContext context,
    SchoolAdminProvider admin,
    UserModel newPrimary,
    String actingUid,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer main admin?'),
        content: Text(
          'Make ${newPrimary.fullName} the main admin? '
          'You will remain an admin but lose transfer privileges.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Transfer')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final transferred = await admin.transferPrimaryAdmin(
      actingAdminUid: actingUid,
      newPrimaryAdminUid: newPrimary.uid,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          transferred
              ? '${newPrimary.fullName} is now the main admin.'
              : admin.error ?? 'Could not transfer.',
        ),
      ),
    );
  }
}

class _GovInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _GovInfoBanner({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.softGreen.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, height: 1.45, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GovInputCard extends StatelessWidget {
  final Widget child;

  const _GovInputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
        ),
      ),
      child: child,
    );
  }
}

class _GovEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _GovEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textSecondary),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  final UserModel user;
  final bool isPrimary;
  final bool isSelf;
  final VoidCallback onRemove;

  const _AdminUserTile({
    required this.user,
    required this.isPrimary,
    required this.isSelf,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
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
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
          child: const Icon(Icons.shield_rounded, color: AppTheme.primaryBlue, size: 20),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Text(
                '(you)',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.softGreen,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
              onPressed: onRemove,
              tooltip: 'Remove admin',
            ),
          ],
        ),
      ),
    );
  }
}
