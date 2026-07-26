import 'package:flutter/material.dart';

import '../../widgets/messaging/messages_inbox.dart';

class ParentMessagesScreen extends StatelessWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessagesInbox(
      title: 'School Messages',
      showStartConversation: true,
    );
  }
}
