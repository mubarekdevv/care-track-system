import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class LinkCodeDialog extends StatelessWidget {
  final String title;
  final String message;
  final String linkCode;
  final String childName;
  final bool showEnrollmentNote;

  const LinkCodeDialog({
    super.key,
    required this.title,
    required this.message,
    required this.linkCode,
    required this.childName,
    this.showEnrollmentNote = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required String linkCode,
    required String childName,
    bool showEnrollmentNote = true,
  }) {
    return showDialog(
      context: context,
      builder: (_) => LinkCodeDialog(
        title: title,
        message: message,
        linkCode: linkCode,
        childName: childName,
        showEnrollmentNote: showEnrollmentNote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Your parent already sees this child after enrollment. The link code connects '
              'the student\'s login to that school profile so they can use homework, badges, and profile.',
              style: TextStyle(fontSize: 11, height: 1.4, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              linkCode,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For $childName',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: linkCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code copied')),
            );
          },
          child: const Text('Copy code'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
