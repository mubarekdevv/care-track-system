import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/message_thread_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final thread = ModalRoute.of(context)?.settings.arguments as MessageThread?;
    if (thread == null) return;

    final messaging = context.read<MessagingProvider>();
    final user = context.read<AuthProvider>().currentUser;
    messaging.watchThreadMessages(thread.id);
    if (user != null) {
      await messaging.markThreadRead(thread: thread, userId: user.uid);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    context.read<MessagingProvider>().stopWatchingMessages();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  Future<void> _send(MessageThread thread) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final messaging = context.read<MessagingProvider>();
    await messaging.sendMessage(
      thread: thread,
      sender: user,
      text: _textController.text,
    );

    if (!mounted) return;
    final err = messaging.errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send: $err')),
      );
      return;
    }

    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thread = ModalRoute.of(context)?.settings.arguments as MessageThread?;
    final user = context.watch<AuthProvider>().currentUser;
    final messaging = context.watch<MessagingProvider>();

    if (thread == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Conversation not found')),
      );
    }

    final otherName = thread.otherPartyName(user.uid);
    final messages = messaging.activeMessages;

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              thread.contextLabel ?? (user.role == 'Parent' ? 'Class teacher' : 'Parent'),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Say hello to start the conversation.',
                      style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final mine = message.isMine(user.uid);
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppTheme.primaryBlue
                                : (isDark ? AppTheme.darkSurface : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(mine ? 16 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 16),
                            ),
                            border: mine
                                ? null
                                : Border.all(
                                    color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                                  ),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: mine
                                  ? Colors.white
                                  : (isDark ? Colors.white : AppTheme.textPrimary),
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: messaging.isSending ? null : (_) => _send(thread),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: messaging.isSending ? null : () => _send(thread),
                  icon: messaging.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
