import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/academic/enrollment_display.dart';
import '../../core/config/school_config.dart';
import '../../core/constants/role_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../providers/teacher_overview_provider.dart';
import '../../providers/teacher_attendance_provider.dart';
import '../../widgets/dashboard/dashboard_hero_header.dart';
import '../../widgets/dashboard/dashboard_tab_scaffold.dart';
import '../../widgets/navigation/kidcare_dashboard_shell.dart';
import '../../widgets/profile/user_profile_avatar.dart';
import '../../widgets/settings/appearance_setting.dart';
import '../auth/teacher_profile_setup_screen.dart';
import '../../widgets/messaging/messages_inbox.dart';
import '../../widgets/messaging/teacher_compose_sheet.dart';
import '../../core/constants/routes.dart';
import '../../providers/messaging_provider.dart';
import 'teacher_homework_tab.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/education_empty_state.dart';
import '../../widgets/care/student_care_sheet.dart';
import '../../widgets/staff/staff_profile_incomplete_banner.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return KidCareDashboardShell(
      selectedIndex: _navIndex,
      onIndexChanged: (index) => setState(() => _navIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'Students',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Attendance',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Homework',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
      children: [
        _TeacherHomeTab(
          user: user,
          onQuickAction: (index) => setState(() => _navIndex = index),
        ),
        const _TeacherStudentsTab(),
        const _TeacherAttendanceTab(),
        const TeacherHomeworkTab(),
        const _TeacherMessagesTab(),
        const _TeacherProfileTab(),
      ],
    );
  }
}

// ==================== OVERVIEW TAB ====================
class _TeacherHomeTab extends StatelessWidget {
  final UserModel? user;
  final ValueChanged<int> onQuickAction;

  const _TeacherHomeTab({
    this.user,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overview = context.watch<TeacherOverviewProvider>();
    final auth = context.watch<AuthProvider>();
    final schoolName =
        context.watch<SchoolAdminProvider>().school?.name ?? 'Your school';
    final accent = RoleStyles.forRole('Teacher')['accent'] as Color;
    final profileIncomplete = !auth.isTeacherProfileComplete;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      body: SafeArea(
        child: overview.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: DashboardHeroHeader(
                      profileUser: user,
                      gradient: RoleStyles.forRole('Teacher')['gradient'] as LinearGradient,
                      accentColor: accent,
                      subtitle: schoolName,
                      title: 'Hello, ${user?.fullName ?? 'Educator'}',
                      badgeText: overview.badgeText,
                    ),
                  ),
                  if (profileIncomplete)
                    SliverToBoxAdapter(
                      child: StaffProfileIncompleteBanner(
                        accentColor: accent,
                        title: 'Finish your teaching profile',
                        message:
                            'Add the grade levels and subjects you teach so your school '
                            'can assign classes and show your student roster.',
                        actionLabel: 'Set up grades & subjects',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TeacherProfileSetupScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _buildQuickStats(isDark, overview),
                  ),
                  SliverToBoxAdapter(
                    child: _TeacherQuickActions(
                      isDark: isDark,
                      rosterCount: overview.rosterCount,
                      onQuickAction: onQuickAction,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Text(
                        'My teaching assignments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (overview.slots.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EducationEmptyState(
                        icon: Icons.link_off_rounded,
                        title: 'Not assigned to a grade yet',
                        message: SchoolConfig.gradeOnlyEnrollment
                            ? 'After you register as Teacher, ask your admin to open '
                                'Admin → Staff tab, link your account to the school, '
                                'then assign you to a grade + subject (e.g. Grade 1 · Math).'
                            : 'After you register as Teacher, ask your admin to open '
                                'Admin → Staff tab, link your account to the school, '
                                'then assign you to a section + subject (e.g. Grade 1-A · Math).',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final slot = overview.slots[index];
                          final count = overview.studentCountForClass(slot.classRoomId);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _ClassScheduleCard(
                              time: count == 0
                                  ? 'No students in this grade yet'
                                  : '$count student${count == 1 ? '' : 's'}',
                              title: slot.subjectName,
                              grade: SchoolConfig.gradeOnlyEnrollment
                                  ? slot.gradeName
                                  : EnrollmentDisplay.teacherSlotLine(
                                      slot.gradeName,
                                      slot.className,
                                    ),
                              icon: slot.icon,
                              accentColor: slot.accentColor,
                              isDark: isDark,
                            ),
                          );
                        },
                        childCount: overview.slots.length,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: _HonestNextStepsCard(
                        rosterCount: overview.rosterCount,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, TeacherOverviewProvider overview) {
    final stats = [
      (
        'Students',
        '${overview.rosterCount}',
        'On your roster',
        const Color(0xFF7ED321),
        Icons.people_rounded
      ),
      (
        SchoolConfig.gradeOnlyEnrollment ? 'Grades' : 'Classes',
        '${overview.slots.length}',
        'Teaching slots',
        const Color(0xFF4A90E2),
        Icons.class_rounded
      ),
      (
        'School',
        overview.slots.isEmpty ? '—' : overview.slots.first.gradeName,
        'Primary assignment',
        const Color(0xFFE2894A),
        Icons.school_rounded
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final s = stats[index];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(s.$5, color: s.$4, size: 20),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: s.$4, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.$2,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  s.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeacherQuickActions extends StatelessWidget {
  final bool isDark;
  final int rosterCount;
  final ValueChanged<int> onQuickAction;

  const _TeacherQuickActions({
    required this.isDark,
    required this.rosterCount,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.groups_rounded, 'My students', 1),
      (Icons.how_to_reg_rounded, 'Attendance', 2),
      (Icons.assignment_rounded, 'Homework', 3),
      (Icons.chat_rounded, 'Messages', 4),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rosterCount > 0
                ? 'Track $rosterCount student${rosterCount == 1 ? '' : 's'}, mark attendance, publish work, and message families.'
                : 'Once students enroll, use these tools every day.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((a) {
              return ActionChip(
                avatar: Icon(a.$1, size: 18, color: const Color(0xFF7ED321)),
                label: Text(a.$2),
                onPressed: () => onQuickAction(a.$3),
                backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                side: BorderSide(
                  color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ClassScheduleCard extends StatelessWidget {
  final String time;
  final String title;
  final String grade;
  final IconData icon;
  final Color accentColor;
  final bool isDark;

  const _ClassScheduleCard({
    required this.time,
    required this.title,
    required this.grade,
    required this.icon,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$grade • $time',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : AppTheme.warmNeutral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Scheduled',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final Color accent;
  final bool isDark;

  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : AppTheme.textSecondary)),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: accent,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== STUDENTS TAB ====================
class _TeacherStudentsTab extends StatefulWidget {
  const _TeacherStudentsTab();

  @override
  State<_TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<_TeacherStudentsTab> {
  String _searchQuery = '';

  Future<void> _messageParent(StudentModel student) async {
    final teacher = context.read<AuthProvider>().currentUser;
    if (teacher == null) return;

    final parent = await context.read<MessagingProvider>().parentContactsFromRoster([student]);
    if (!mounted || parent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find parent contact for this student.')),
      );
      return;
    }

    final thread = await context.read<MessagingProvider>().ensureTeacherToParentThread(
          teacher: teacher,
          contact: parent.first,
        );
    if (!mounted) return;
    if (thread == null) {
      final err = context.read<MessagingProvider>().errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    AppRoutes.push(context, AppRoutes.chat, arguments: thread);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attendance = context.watch<TeacherAttendanceProvider>();
    final overview = context.watch<TeacherOverviewProvider>();
    final schoolAdmin = context.watch<SchoolAdminProvider>();

    if (attendance.isLoading && overview.isLoading) {
      return const DashboardTabScaffold(
        title: 'My Students',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roster = overview.roster.isNotEmpty ? overview.roster : attendance.roster;
    final q = _searchQuery.trim().toLowerCase();
    final list = q.isEmpty
        ? roster
        : roster.where((s) => s.fullName.toLowerCase().contains(q)).toList();

    if (roster.isEmpty) {
      final loadError = overview.error ?? attendance.error;
      return DashboardTabScaffold(
        title: 'My Students',
        body: EducationEmptyState(
          icon: overview.slots.isEmpty ? Icons.link_off_rounded : Icons.groups_outlined,
          title: overview.slots.isEmpty
              ? 'Waiting for admin assignment'
              : 'No students on your roster yet',
          message: loadError != null
              ? (loadError.contains('permission-denied')
                  ? 'Firestore blocked reading students. Deploy the latest rules: '
                      'run "firebase deploy --only firestore:rules" in the project folder, '
                      'then restart the app.\n\n$loadError'
                  : 'Could not load roster: $loadError')
              : overview.slots.isEmpty
                  ? 'Ask admin to assign you in Admin → Staff tab after you register as Teacher.'
                  : 'Students appear here after parents enroll children in your assigned grade.',
        ),
      );
    }

    return DashboardTabScaffold(
      title: 'My Students',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TeacherComposeSheet.show(context),
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Message parent'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No students match your search.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = list[index];
                      final gradeLabel = EnrollmentDisplay.classOrGradeLabel(
                        schoolAdmin,
                        student.classRoomId,
                        gradeLevelId: student.gradeLevelId,
                      );
                      final present = attendance.isPresent(student.id);
                      return Material(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          onTap: () => StudentCareSheet.show(
                            context,
                            student: student,
                            accentColor: const Color(0xFF7ED321),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                            child: Text(
                              student.fullName.isNotEmpty
                                  ? student.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            gradeLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  present ? 'Present' : 'Absent',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: present
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.orange.withValues(alpha: 0.12),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                tooltip: 'Message parent',
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                onPressed: () => _messageParent(student),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== ATTENDANCE TAB ====================
class _TeacherAttendanceTab extends StatefulWidget {
  const _TeacherAttendanceTab();

  @override
  State<_TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<_TeacherAttendanceTab> {
  String _searchQuery = '';
  String? _classRoomFilter;

  List<StudentModel> _filter(List<StudentModel> students, SchoolAdminProvider admin) {
    var list = students;
    if (_classRoomFilter != null && _classRoomFilter!.isNotEmpty) {
      if (SchoolConfig.gradeOnlyEnrollment) {
        final gradeId = admin.gradeLevelIdForClassRoom(_classRoomFilter!);
        if (gradeId != null && gradeId.isNotEmpty) {
          list = list.where((s) => s.gradeLevelId == gradeId).toList();
        }
      } else {
        list = list.where((s) => s.classRoomId == _classRoomFilter).toList();
      }
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((s) => s.fullName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teacherId = context.watch<AuthProvider>().currentUser?.uid;
    final attendance = context.watch<TeacherAttendanceProvider>();
    final overview = context.watch<TeacherOverviewProvider>();
    final schoolAdmin = context.watch<SchoolAdminProvider>();

    if (teacherId == null) {
      return const DashboardTabScaffold(
        title: 'Attendance Registry',
        body: Center(child: Text('Please sign in again.')),
      );
    }

    if (attendance.isLoading && overview.isLoading) {
      return const DashboardTabScaffold(
        title: 'Attendance Registry',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roster = overview.roster.isNotEmpty ? overview.roster : attendance.roster;
    final list = _filter(roster, schoolAdmin);
    final presentCount =
        list.where((s) => attendance.isPresent(s.id)).length;
    final rate = list.isEmpty
        ? 0
        : ((presentCount / list.length) * 100).round();

    if (roster.isEmpty) {
      return DashboardTabScaffold(
        title: 'Attendance Registry',
        body: EducationEmptyState(
          icon: overview.slots.isEmpty ? Icons.link_off_rounded : Icons.groups_outlined,
          title: overview.slots.isEmpty
              ? 'Waiting for admin assignment'
              : 'No students on your roster yet',
          message: overview.slots.isEmpty
              ? 'Ask admin to assign you in Admin → Staff tab after you register as Teacher.'
              : 'Students appear here after parents enroll children in your assigned grade '
                  '(${overview.slots.map((s) => SchoolConfig.gradeOnlyEnrollment ? s.gradeName : EnrollmentDisplay.teacherSlotLine(s.gradeName, s.className)).toSet().join(', ')}).',
        ),
      );
    }

    return DashboardTabScaffold(
      title: 'Attendance Registry',
      body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Today\'s Ratio',
                                    style: TextStyle(
                                        fontSize: 12, color: AppTheme.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  '$presentCount / ${list.length} Present',
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7ED321).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$rate% Rate',
                              style: const TextStyle(
                                color: Color(0xFF7ED321),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (overview.slots.length > 1) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _classRoomFilter,
                        decoration: InputDecoration(
                          labelText: SchoolConfig.gradeOnlyEnrollment
                              ? 'Filter by grade'
                              : 'Filter by section',
                          filled: true,
                          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All my grades'),
                          ),
                          ...overview.slots.map(
                            (s) => DropdownMenuItem(
                              value: s.classRoomId,
                              child: Text(
                                SchoolConfig.gradeOnlyEnrollment
                                    ? s.gradeName
                                    : EnrollmentDisplay.teacherSlotLine(
                                        s.gradeName,
                                        s.className,
                                      ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _classRoomFilter = v),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search students...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          'No students match your search.',
                          style: TextStyle(
                              color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = list[index];
                          final isPresent = attendance.isPresent(student.id);
                          final age = student.displayAge;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPresent
                                    ? const Color(0xFF7ED321).withValues(alpha: 0.3)
                                    : (isDark
                                        ? Colors.grey.shade800
                                        : AppTheme.inputBorder),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: student.imageUrl.isNotEmpty
                                      ? NetworkImage(student.imageUrl)
                                      : null,
                                  backgroundColor: isPresent
                                      ? const Color(0xFF7ED321).withValues(alpha: 0.12)
                                      : Colors.redAccent.withValues(alpha: 0.1),
                                  child: student.imageUrl.isEmpty
                                      ? Text(
                                          student.fullName.isNotEmpty
                                              ? student.fullName[0]
                                              : '?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isPresent
                                                ? const Color(0xFF7ED321)
                                                : Colors.redAccent,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.fullName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        age != null
                                            ? 'Enrolled • $age years old'
                                            : 'Enrolled student',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isPresent,
                                  activeThumbColor: const Color(0xFF7ED321),
                                  activeTrackColor:
                                      const Color(0xFF7ED321).withValues(alpha: 0.2),
                                  onChanged: attendance.isSaving
                                      ? null
                                      : (value) async {
                                          await attendance.setPresent(
                                            student: student,
                                            teacherId: teacherId,
                                            present: value,
                                          );
                                          if (!context.mounted) return;
                                          if (attendance.error != null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(attendance.error!)),
                                            );
                                            return;
                                          }
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${student.fullName} saved as ${value ? 'present' : 'absent'}',
                                              ),
                                              duration: const Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              margin: const EdgeInsets.all(12),
                                            ),
                                          );
                                        },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
    );
  }
}

class _HonestNextStepsCard extends StatelessWidget {
  final int rosterCount;
  final bool isDark;

  const _HonestNextStepsCard({
    required this.rosterCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you can do now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            rosterCount == 0
                ? 'Once admin assigns you (Staff tab) and parents enroll students in your '
                    'grade, mark attendance here and publish homework from the Homework tab.'
                : 'You have $rosterCount student(s) in your grade(s). '
                    'Mark attendance daily and publish homework for each subject you teach.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MESSAGES TAB ====================
class _TeacherMessagesTab extends StatelessWidget {
  const _TeacherMessagesTab();

  @override
  Widget build(BuildContext context) {
    return const MessagesInbox(title: 'Inbox Communication', isTeacherInbox: true);
  }
}

// ==================== PROFILE TAB ====================
class _TeacherProfileTab extends StatelessWidget {
  const _TeacherProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final school = context.watch<SchoolAdminProvider>();
    final overview = context.watch<TeacherOverviewProvider>();
    final schoolLabel = school.school?.name ?? 'School not loaded';
    final assignmentLabel = overview.slots.isEmpty
        ? 'Not assigned yet'
        : overview.slots.map((s) => s.displayLabel).join(' · ');
    final rosterLabel =
        overview.rosterCount == 0 ? 'No enrolled students' : '${overview.rosterCount} students';

    return DashboardTabScaffold(
      title: 'Profile Settings',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(child: UserProfileAvatar(radius: 44, user: user)),
          const SizedBox(height: 8),
          Text(
            'Tap your photo to update',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Teacher',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? 'educator@kidcare.com',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Center(
            child: Chip(
              label: Text(
                user?.role ?? 'Teacher',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF7ED321).withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
            ),
            child: Column(
              children: [
                _ProfileStatRow(label: 'School', value: schoolLabel),
                const Divider(),
                _ProfileStatRow(label: 'Assignments', value: assignmentLabel),
                const Divider(),
                _ProfileStatRow(label: 'Roster', value: rosterLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TeacherProfileSetupScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Update grades & subjects I teach'),
            ),
          ),
          const SizedBox(height: 16),
          const AppearanceSetting(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).logout();
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
