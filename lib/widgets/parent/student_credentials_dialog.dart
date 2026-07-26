import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../services/family_account_service.dart';

/// One-time display of student login credentials after provisioning.
class StudentCredentialsDialog extends StatelessWidget {
  final CreateStudentAccountResult result;

  const StudentCredentialsDialog({super.key, required this.result});

  static Future<void> show(
    BuildContext context, {
    required CreateStudentAccountResult result,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StudentCredentialsDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.key_rounded, color: AppTheme.primaryBlue),
          SizedBox(width: 10),
          Expanded(child: Text('Student login created')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share these credentials with your child. They must change the password on first sign-in.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _CredentialRow(label: 'Email', value: result.studentEmail),
          const SizedBox(height: 10),
          _CredentialRow(label: 'Temporary password', value: result.temporaryPassword),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text:
                    'Email: ${result.studentEmail}\nTemporary password: ${result.temporaryPassword}',
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          child: const Text('Copy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
