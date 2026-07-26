import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../widgets/dashboard/dashboard_tab_scaffold.dart';
import 'healthcare_compose_sheet.dart';
import 'message_thread_tile.dart';
import 'parent_start_chat_sheet.dart';
import 'teacher_compose_sheet.dart';

class MessagesInbox extends StatelessWidget {
  final String title;
  final bool showStartConversation;
  final bool isTeacherInbox;
  final bool isHealthcareInbox;

  const MessagesInbox({
    super.key,
    required this.title,
    this.showStartConversation = false,
    this.isTeacherInbox = false,
    this.isHealthcareInbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messaging = context.watch<MessagingProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    return DashboardTabScaffold(
      title: title,
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (isHealthcareInbox) {
                  HealthcareComposeSheet.show(context);
                } else if (isTeacherInbox) {
                  TeacherComposeSheet.show(context);
                } else if (showStartConversation) {
                  ParentStartChatSheet.show(context);
                }
              },
              icon: const Icon(Icons.edit_rounded),
              label: Text(
                isHealthcareInbox
                    ? 'Message parent'
                    : isTeacherInbox
                        ? 'Message parent'
                        : 'New message',
              ),
            ),
      body: messaging.isLoading
          ? const Center(child: CircularProgressIndicator())
          : messaging.threads.isEmpty
              ? _EmptyInbox(
                  isDark: isDark,
                  showStartConversation: showStartConversation || isTeacherInbox || isHealthcareInbox,
                  isTeacher: isTeacherInbox,
                  isHealthcare: isHealthcareInbox,
                  onStart: user == null
                      ? null
                      : () {
                          if (isHealthcareInbox) {
                            HealthcareComposeSheet.show(context);
                          } else if (isTeacherInbox) {
                            TeacherComposeSheet.show(context);
                          } else {
                            ParentStartChatSheet.show(context);
                          }
                        },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
                  itemCount: messaging.threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final thread = messaging.threads[index];
                    return MessageThreadTile(
                      thread: thread,
                      isDark: isDark,
                      onTap: () => AppRoutes.push(
                        context,
                        AppRoutes.chat,
                        arguments: thread,
                      ),
                    );
                  },
                ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  final bool isDark;
  final bool showStartConversation;
  final bool isTeacher;
  final bool isHealthcare;
  final VoidCallback? onStart;

  const _EmptyInbox({
    required this.isDark,
    required this.showStartConversation,
    this.isTeacher = false,
    this.isHealthcare = false,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: isDark ? Colors.grey[600] : AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isHealthcare
                  ? 'Message parents of students assigned to your clinic caseload.'
                  : isTeacher
                      ? 'Message parents of students in your assigned classes only.'
                      : 'Message teachers and doctors connected to your children.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSecondary, height: 1.4),
            ),
            if (showStartConversation && onStart != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.chat_rounded),
                label: Text(
                  isHealthcare || isTeacher ? 'Message parent' : 'New message',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
