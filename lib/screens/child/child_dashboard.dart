import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/role_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_gamification_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/dashboard/dashboard_hero_header.dart';
import '../../widgets/dashboard/dashboard_tab_scaffold.dart';
import '../../widgets/navigation/kidcare_dashboard_shell.dart';
import '../../widgets/profile/user_profile_avatar.dart';
import '../../widgets/settings/appearance_setting.dart';
import '../../widgets/family/student_parent_link_code_action.dart';
import '../../widgets/messaging/messages_inbox.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  int _navIndex = 0;

  void _goToTasks() => setState(() => _navIndex = 1);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Stack(
      children: [
        const _ChildLiveDataBinder(),
        KidCareDashboardShell(
      selectedIndex: _navIndex,
      onIndexChanged: (index) => setState(() => _navIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.stars_outlined),
          selectedIcon: Icon(Icons.stars_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'My Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events_rounded),
          label: 'My Badges',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.face_outlined),
          selectedIcon: Icon(Icons.face_rounded),
          label: 'My Profile',
        ),
      ],
      children: [
        _ChildHomeTab(onOpenTasks: _goToTasks, user: user),
        const _ChildHomeworkTab(),
        const _ChildRewardsTab(),
        const _ChildMessagesTab(),
        const _ChildProfileTab(),
      ],
        ),
      ],
    );
  }
}

class _ChildLiveDataBinder extends StatefulWidget {
  const _ChildLiveDataBinder();

  @override
  State<_ChildLiveDataBinder> createState() => _ChildLiveDataBinderState();
}

class _ChildLiveDataBinderState extends State<_ChildLiveDataBinder> {
  String? _bindKey;

  void _syncIfNeeded() {
    final user = context.read<AuthProvider>().currentUser;
    final linked = context.read<ChildProvider>().linkedChild;
    final school = context.read<SchoolAdminProvider>();
    final linkedId = user?.linkedStudentId;
    final isLinked = linkedId != null && linkedId.isNotEmpty;

    var classRoomId = linked?.classRoomId;
    if ((classRoomId == null || classRoomId.isEmpty) &&
        linked?.gradeLevelId != null &&
        linked!.gradeLevelId!.isNotEmpty) {
      classRoomId = school.primaryClassForGrade(linked.gradeLevelId!)?.id;
    }

    final key =
        '$isLinked|${linked?.id ?? linkedId}|$classRoomId|${linked?.gradeLevelId}|${school.subjects.length}|${school.classes.length}';
    if (key == _bindKey) return;
    _bindKey = key;

    context.read<ChildGamificationProvider>().bindStudentExperience(
          isAccountLinked: isLinked,
          studentId: linked?.id ?? linkedId,
          classRoomId: classRoomId,
          subjectNameFor: school.subjectNameForId,
          linkedChild: linked,
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ==================== HOME TAB ====================
class _ChildHomeTab extends StatelessWidget {
  final VoidCallback onOpenTasks;
  final UserModel? user;
  const _ChildHomeTab({
    required this.onOpenTasks,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<ChildGamificationProvider>(context);
    final linked = context.watch<ChildProvider>().linkedChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = game.homeworkStatusMessage;
    final schedule = game.activeSchedule;
    final displayName = linked?.name.isNotEmpty == true
        ? linked!.name
        : (user?.fullName ?? 'Explorer');

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _PlayfulHeader(
                user: user,
                name: displayName,
                level: game.currentLevel,
                xp: game.currentXp,
                xpProgress: game.xpProgress,
                badgeCount: game.unlockedBadgeCount,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Active Quests',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2),
                    ),
                    if (game.pendingQuestCount > 0)
                      TextButton(
                        onPressed: onOpenTasks,
                        child: const Text('View all',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
                child: _QuestStats(
                    rank: game.rankTitle,
                    pending: game.pendingQuestCount,
                    isDark: isDark)),
            if (status != null && game.pendingQuestCount == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _HomeworkStatusBanner(message: status, isDark: isDark),
                ),
              ),
            if (game.pendingQuestCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _NextQuestCard(
                    quest: game.quests.firstWhere((q) => !q.completed),
                    onTap: onOpenTasks,
                    isDark: isDark,
                  ),
                ),
              ),
            if (game.attendanceTodayLabel != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _AttendanceChip(label: game.attendanceTodayLabel!, isDark: isDark),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Journey',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2),
                    ),
                    if (game.isScheduleLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7ED321).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          game.currentScheduleItem != null ? 'Live now' : 'Your classes',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7ED321),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (schedule.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _HomeworkStatusBanner(
                    message: game.isScheduleLive
                        ? 'Your class schedule will appear when teachers are assigned to your grade.'
                        : 'Link your parent code and enroll in a grade to see your real school day.',
                    isDark: isDark,
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = schedule[index];
                    final isCurrent = game.currentScheduleItem?.time == item.time &&
                        game.currentScheduleItem?.title == item.title;
                    final isNext = game.nextScheduleItem?.time == item.time &&
                        game.nextScheduleItem?.title == item.title;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _ScheduleCard(
                        item: item,
                        isDark: isDark,
                        isCurrent: isCurrent,
                        isNext: isNext,
                      ),
                    );
                  },
                  childCount: schedule.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _PlayfulHeader extends StatelessWidget {
  final UserModel? user;
  final String name;
  final int level;
  final int xp;
  final double xpProgress;
  final int badgeCount;

  const _PlayfulHeader({
    this.user,
    required this.name,
    required this.level,
    required this.xp,
    required this.xpProgress,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardHeroHeader(
      profileUser: user,
      gradient: RoleStyles.forRole('Child')['gradient'] as LinearGradient,
      accentColor: RoleStyles.forRole('Child')['accent'] as Color,
      subtitle: 'Level $level Explorer',
      title: name,
      avatarOnRight: false,
      showGradientRing: false,
      margin: const EdgeInsets.all(20),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 6),
            Text(
              '$badgeCount Badges',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Progress (XP)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$xp / ${ChildGamificationProvider.xpPerLevel} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: xpProgress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: Colors.amber,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _AttendanceChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final present = label.toLowerCase().contains('present');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (present ? const Color(0xFF7ED321) : Colors.orange)
            .withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (present ? const Color(0xFF7ED321) : Colors.orange).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            present ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 20,
            color: present ? const Color(0xFF7ED321) : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkStatusBanner extends StatelessWidget {
  final String message;
  final bool isDark;

  const _HomeworkStatusBanner({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 20, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestStats extends StatelessWidget {
  final String rank;
  final int pending;
  final bool isDark;

  const _QuestStats(
      {required this.rank, required this.pending, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
              ),
              child: Column(
                children: [
                  const Text('Pending Quests',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    '$pending',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: pending > 0
                          ? const Color(0xFF9013FE)
                          : const Color(0xFF7ED321),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
              ),
              child: Column(
                children: [
                  const Text('Level Rank',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    rank,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextQuestCard extends StatelessWidget {
  final ChildQuest quest;
  final VoidCallback onTap;
  final bool isDark;

  const _NextQuestCard(
      {required this.quest, required this.onTap, required this.isDark});

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
            border: Border.all(color: quest.color.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: quest.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Up next',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.textSecondary)),
                      Text(quest.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Text('+${quest.xp} XP',
                    style: TextStyle(
                        color: quest.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final bool isDark;
  final bool isCurrent;
  final bool isNext;

  const _ScheduleCard({
    required this.item,
    required this.isDark,
    required this.isCurrent,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? item.color.withValues(alpha: 0.6)
              : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                    color: item.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
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
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isCurrent ? item.color : null,
                        ),
                      ),
                    ),
                    if (isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Up next',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: item.color)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subtitle} • ${item.time}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TASKS TAB ====================
class _ChildHomeworkTab extends StatelessWidget {
  const _ChildHomeworkTab();

  Future<void> _completeTask(BuildContext context, ChildQuest quest) async {
    final game = context.read<ChildGamificationProvider>();
    final user = context.read<AuthProvider>().currentUser;
    final linked = context.read<ChildProvider>().linkedChild;
    final studentName = linked?.name.isNotEmpty == true
        ? linked!.name
        : (user?.fullName ?? 'Student');

    if (game.isSubmittingQuest) return;

    try {
      final unlockedBadge = await game.completeQuestAsync(
        questId: quest.id,
        studentName: studentName,
        submittedByUserId: user?.uid ?? '',
        onLevelUp: () => _showLevelUpDialog(context, game.currentLevel),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Turned in! +${quest.xp} XP — your teacher can see this.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7ED321),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      if (unlockedBadge != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (context.mounted) _showBadgeUnlockDialog(context, unlockedBadge);
        });
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not turn in homework. Check your connection and try again.'),
        ),
      );
    }
  }

  void _showLevelUpDialog(BuildContext context, int level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text('🎉 LEVEL UP! 🎉',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 22)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟 AMAZING WORK! 🌟',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text('You reached Level $level!', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const Icon(Icons.workspace_premium_rounded,
                size: 72, color: Colors.amber),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Awesome!',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBadgeUnlockDialog(BuildContext context, String badgeTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('New Badge Unlocked!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 64, color: Colors.amber),
            const SizedBox(height: 12),
            Text(badgeTitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Collect!')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final game = Provider.of<ChildGamificationProvider>(context);
    final list = game.quests;

    if (game.isHomeworkLoading) {
      return const DashboardTabScaffold(
        title: 'My Homework Quests',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (list.isEmpty) {
      return DashboardTabScaffold(
        title: 'My Homework Quests',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 56,
                  color: isDark ? Colors.grey[600] : AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  game.isLiveHomework ? 'No homework quests yet' : 'Homework not available',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  game.homeworkStatusMessage ??
                      'Your teachers will post homework here when you are enrolled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.4,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DashboardTabScaffold(
      title: 'My Homework Quests',
      body: list.every((q) => q.completed)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.celebration_rounded,
                        size: 64, color: Color(0xFF7ED321)),
                    const SizedBox(height: 16),
                    const Text('All quests complete!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      'You earned ${game.unlockedBadgeCount} badges. Check your vault!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = list[index];
                return _QuestTile(
                    task: task,
                    isDark: isDark,
                    onClaim: () => _completeTask(context, task));
              },
            ),
    );
  }
}

class _QuestTile extends StatefulWidget {
  final ChildQuest task;
  final bool isDark;
  final Future<void> Function() onClaim;

  const _QuestTile(
      {required this.task, required this.isDark, required this.onClaim});

  @override
  State<_QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends State<_QuestTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final completed = task.completed;
    final accent = task.color;
    final submitting = context.watch<ChildGamificationProvider>().isSubmittingQuest;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: completed
                ? const Color(0xFF7ED321).withValues(alpha: 0.3)
                : (widget.isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.subject,
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      color: completed
                          ? Colors.grey
                          : (widget.isDark
                              ? Colors.white
                              : AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 12,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(task.dueDate,
                          style: TextStyle(
                              fontSize: 10,
                              color: widget.isDark
                                  ? Colors.grey[400]
                                  : AppTheme.textSecondary)),
                      const SizedBox(width: 14),
                      const Icon(Icons.bolt_rounded,
                          size: 12, color: Colors.amber),
                      Text('+${task.xp} XP',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (completed)
              const CircleAvatar(
                backgroundColor: Color(0xFF7ED321),
                child: Icon(Icons.check_rounded, color: Colors.white),
              )
            else
              GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                child: ElevatedButton(
                  onPressed: submitting ? null : () => widget.onClaim(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Turn in',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== BADGES TAB ====================
class _ChildRewardsTab extends StatelessWidget {
  const _ChildRewardsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final game = Provider.of<ChildGamificationProvider>(context);
    final badges = game.badges;

    return DashboardTabScaffold(
      title: 'My Vault Badges',
      trailingActions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${game.unlockedBadgeCount}/${badges.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
          ),
        ),
      ],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                  ),
                ),
                child: Text(
                  'Badges unlock when you turn in homework: Science Explorer (science task), '
                  'Math Whiz (3 tasks), Fast Learner (all tasks). Progress saves to your school profile.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = badges[index];
                  return _BadgeCard(badge: badge, isDark: isDark);
                },
                childCount: badges.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final ChildBadge badge;
  final bool isDark;

  const _BadgeCard({required this.badge, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    final accent = badge.color;

    return Opacity(
      opacity: unlocked ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked
                ? accent.withValues(alpha: 0.3)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: unlocked
                    ? accent.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(badge.icon,
                  color: unlocked ? accent : Colors.grey, size: 32),
            ),
            const SizedBox(height: 10),
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: unlocked
                    ? (isDark ? Colors.white : AppTheme.textPrimary)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
            ),
            if (!unlocked) ...[
              const SizedBox(height: 6),
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== MESSAGES TAB ====================
class _ChildMessagesTab extends StatelessWidget {
  const _ChildMessagesTab();

  @override
  Widget build(BuildContext context) {
    return const MessagesInbox(
      title: 'Clinic Messages',
      showStartConversation: false,
    );
  }
}

// ==================== PROFILE TAB ====================
class _ChildProfileTab extends StatelessWidget {
  const _ChildProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final game = Provider.of<ChildGamificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardTabScaffold(
      title: 'My Profile',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(child: UserProfileAvatar(radius: 44, user: user)),
          const SizedBox(height: 8),
          Text(
            'Tap your photo to update (shown to your parent too)',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Emma Watson',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? 'emma@kidcare.com',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Center(
            child: Chip(
              label: Text(user?.role ?? 'Child',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF9013FE).withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
            ),
            child: Column(
              children: [
                _ProfileStatRow(label: 'Level', value: '${game.currentLevel}'),
                const Divider(),
                _ProfileStatRow(label: 'Total XP', value: '${game.currentXp}'),
                const Divider(),
                _ProfileStatRow(
                    label: 'Badges', value: '${game.unlockedBadgeCount}'),
                const Divider(),
                const _ProfileStatRow(
                    label: 'Assigned Class', value: 'Grade 3-A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const StudentParentLinkCodeTile(),
          const SizedBox(height: 8),
          const AppearanceSetting(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false)
                    .logout();
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('Sign Out',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
