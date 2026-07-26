import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/message_thread_model.dart';
import '../../providers/auth_provider.dart';

class MessageThreadTile extends StatelessWidget {
  final MessageThread thread;
  final bool isDark;
  final VoidCallback onTap;

  const MessageThreadTile({
    super.key,
    required this.thread,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser?.uid ?? '';
    final unread = thread.isUnreadFor(userId);
    final otherName = thread.otherPartyName(userId);

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? AppTheme.primaryBlue.withValues(alpha: 0.35)
                  : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
              width: unread ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                child: Icon(
                  thread.isHealthcareThread
                      ? Icons.medical_services_rounded
                      : userId == thread.parentId
                          ? Icons.school_rounded
                          : Icons.person_rounded,
                  color: thread.isHealthcareThread
                      ? const Color(0xFFE2894A)
                      : AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: unread
                                  ? AppTheme.primaryBlue
                                  : (isDark ? Colors.white : AppTheme.textPrimary),
                            ),
                          ),
                        ),
                        Text(
                          thread.timeLabel(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (thread.contextLabel != null)
                      Text(
                        thread.contextLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                        color: unread
                            ? (isDark ? Colors.white : AppTheme.textPrimary)
                            : (isDark ? Colors.grey[400] : AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
