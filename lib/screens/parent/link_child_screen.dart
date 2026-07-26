import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/domain/domain_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';

/// Parent enters a 6-digit code from their child (free plan — no Cloud Functions).
class LinkChildScreen extends StatefulWidget {
  const LinkChildScreen({super.key});

  @override
  State<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends State<LinkChildScreen> {
  final _codeController = TextEditingController();
  RelationshipType _relationship = RelationshipType.guardian;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final parentId = context.read<AuthProvider>().currentUser?.uid;
    if (parentId == null) return;

    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the full 6-digit code from your child.')),
      );
      return;
    }

    final name = await context.read<ChildProvider>().claimChildWithLinkCode(
          parentId: parentId,
          code: code,
          relationshipType: _relationship,
        );

    if (!mounted) return;
    if (name != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Linked to $name. They appear under My Children.'),
          backgroundColor: AppTheme.softGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      final raw = context.read<ChildProvider>().errorMessage ?? 'Could not link child.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(raw.replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loading = context.watch<ChildProvider>().isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(title: const Text('Link with code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If your child registered on their own, ask them for their 6-digit code '
              '(Profile → My parent link code, or the screen right after they signed up).',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.softGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Steps: 1) Child shares code  2) You enter it below  '
                '3) Child appears on your Home tab',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Link code',
                hintText: '123456',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RelationshipType>(
              initialValue: _relationship,
              items: RelationshipType.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _relationship = v);
              },
              decoration: const InputDecoration(labelText: 'Your relationship'),
            ),
            const Spacer(),
            AuthPrimaryButton(
              label: loading ? 'Linking…' : 'Link child',
              onPressed: loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
