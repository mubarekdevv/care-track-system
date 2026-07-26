import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/academic/enrollment_display.dart';
import '../../core/theme/app_theme.dart';
import '../../data/firestore/firestore_academic_repository.dart';
import '../../models/academic_models.dart';
import '../../models/child_activity_event.dart';
import '../../models/child_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/dashboard/simple_bar_chart.dart';
import '../../widgets/parent/child_account_link_status_chip.dart';
import '../../widgets/parent/parent_child_link_code_action.dart';
import '../../widgets/parent/parent_health_module_panel.dart';
import '../../widgets/profile/kidcare_avatar_image.dart';
import '../../widgets/navigation/kidcare_section_tab_bar.dart';

class ChildTimelineRouteArgs {
  final ChildModel child;
  final int initialTabIndex;

  const ChildTimelineRouteArgs({
    required this.child,
    this.initialTabIndex = 0,
  });
}

class ChildTimelineScreen extends StatefulWidget {
  const ChildTimelineScreen({super.key});

  @override
  State<ChildTimelineScreen> createState() => _ChildTimelineScreenState();
}

class _ChildTimelineScreenState extends State<ChildTimelineScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  ChildModel? _child;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_child != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ChildTimelineRouteArgs) {
      _child = args.child;
      final tab = args.initialTabIndex.clamp(0, 2);
      if (_tabController.index != tab) {
        _tabController.index = tab;
      }
    } else if (args is ChildModel) {
      _child = args;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ChildModel? _resolveChild(ChildProvider provider) {
    final local = _child;
    if (local == null) return null;
    for (final c in provider.children) {
      if (c.id == local.id) return c;
    }
    return local;
  }

  String _classLabel(SchoolAdminProvider school, ChildModel child) {
    return EnrollmentDisplay.classOrGradeLabel(
      school,
      child.classRoomId,
      gradeLevelId: child.gradeLevelId,
      fallback: 'Not enrolled yet',
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _resolveChild(context.watch<ChildProvider>());
    if (child == null) {
      return const Scaffold(body: Center(child: Text('Child not found')));
    }

    final school = context.watch<SchoolAdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            actions: [
              ParentChildLinkCodeIconButton(
                child: child,
                iconColor: Colors.white,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        KidCareAvatarImage(
                          photoUrl: child.imageUrl,
                          name: child.name,
                          radius: 36,
                          accent: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                child.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${child.age} years • ${_classLabel(school, child)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              ChildAccountLinkStatusChip(child: child),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: KidCareSectionTabBar(
              controller: _tabController,
              isDark: isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TimelineTab(child: child, isDark: isDark, school: school),
            _AcademicsTab(child: child, isDark: isDark, school: school),
            _HealthTab(child: child, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final ChildModel child;
  final bool isDark;
  final SchoolAdminProvider school;

  const _TimelineTab({
    required this.child,
    required this.isDark,
    required this.school,
  });

  @override
  Widget build(BuildContext context) {
    if (child.classRoomId == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            isDark: isDark,
            title: 'Timeline',
            child: Text(
              'Enroll ${child.name} in a grade to see attendance, homework, and grade events.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    final repo = FirestoreAcademicRepository();
    return StreamBuilder<List<AssessmentModel>>(
      stream: repo.watchPublishedAssessmentsForStudent(child.id),
      builder: (context, gradeSnap) {
        return StreamBuilder<List<AttendanceRecordModel>>(
          stream: repo.watchRecentAttendanceForStudent(child.id, maxRecords: 20),
          builder: (context, attSnap) {
            return StreamBuilder<List<AssignmentModel>>(
              stream: repo.watchAssignmentsForStudent(child.id),
              builder: (context, hwSnap) {
                if (gradeSnap.connectionState == ConnectionState.waiting &&
                    attSnap.connectionState == ConnectionState.waiting &&
                    hwSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = ChildActivityEvent.merge(
                  attendance: attSnap.data ?? [],
                  assessments: gradeSnap.data ?? [],
                  assignments: hwSnap.data ?? [],
                  subjectNameFor: school.subjectNameForId,
                );

                if (events.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _SectionCard(
                        isDark: isDark,
                        title: 'Timeline',
                        child: Text(
                          'No activity yet.\n\nEvents appear when teachers mark attendance, assign homework, or publish grades.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _TimelineEventTile(event: events[index], isDark: isDark);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  final ChildActivityEvent event;
  final bool isDark;

  const _TimelineEventTile({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d • h:mm a').format(event.at);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(event.icon, size: 18, color: event.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  event.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : AppTheme.textSecondary,
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

class _AcademicsTab extends StatelessWidget {
  final ChildModel child;
  final bool isDark;
  final SchoolAdminProvider school;

  const _AcademicsTab({
    required this.child,
    required this.isDark,
    required this.school,
  });

  @override
  Widget build(BuildContext context) {
    if (child.classRoomId == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            isDark: isDark,
            title: 'Academics',
            child: Text(
              'Enroll ${child.name} in a grade to view homework and published grades.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    final repo = FirestoreAcademicRepository();
    return StreamBuilder<List<AssignmentModel>>(
      stream: repo.watchAssignmentsForStudent(child.id),
      builder: (context, hwSnap) {
        return StreamBuilder<List<AssessmentModel>>(
          stream: repo.watchPublishedAssessmentsForStudent(child.id),
          builder: (context, gradeSnap) {
            if (hwSnap.connectionState == ConnectionState.waiting &&
                gradeSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final assignments = hwSnap.data ?? [];
            final assessments = gradeSnap.data ?? [];
            final chartData = _subjectChartData(assessments, school);

            return ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                if (chartData != null) ...[
                  _SectionCard(
                    isDark: isDark,
                    title: 'Subject performance',
                    child: SimpleBarChart(
                      labels: chartData.labels,
                      values: chartData.values,
                      barColor: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _SectionCard(
                  isDark: isDark,
                  title: 'Homework (${assignments.length})',
                  child: assignments.isEmpty
                      ? Text(
                          'No homework assigned yet for this class.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                          ),
                        )
                      : Column(
                          children: assignments
                              .map(
                                (a) => _HomeworkRow(
                                  assignment: a,
                                  school: school,
                                  isDark: isDark,
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  isDark: isDark,
                  title: 'Published grades (${assessments.length})',
                  child: assessments.isEmpty
                      ? Text(
                          'Teachers publish grades after homework is graded.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                          ),
                        )
                      : Column(
                          children: assessments
                              .map(
                                (a) => _GradeRow(
                                  assessment: a,
                                  school: school,
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  ({List<String> labels, List<double> values})? _subjectChartData(
    List<AssessmentModel> assessments,
    SchoolAdminProvider school,
  ) {
    if (assessments.isEmpty) return null;

    final bySubject = <String, List<double>>{};
    for (final a in assessments) {
      final pct = a.percentage;
      if (pct == null) continue;
      final name = school.subjectNameForId(a.subjectId) ?? 'Other';
      bySubject.putIfAbsent(name, () => []).add(pct);
    }
    if (bySubject.isEmpty) return null;

    final labels = bySubject.keys.toList()..sort();
    final values = labels
        .map((label) {
          final scores = bySubject[label]!;
          return scores.reduce((a, b) => a + b) / scores.length;
        })
        .toList();

    return (labels: labels.take(4).toList(), values: values.take(4).toList());
  }
}

class _HomeworkRow extends StatelessWidget {
  final AssignmentModel assignment;
  final SchoolAdminProvider school;
  final bool isDark;

  const _HomeworkRow({
    required this.assignment,
    required this.school,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subject = school.subjectNameForId(assignment.subjectId) ?? 'Subject';
    final due = assignment.dueAt;
    final isOverdue = due != null && due.isBefore(DateTime.now());
    final dueLabel = due == null
        ? 'No due date'
        : isOverdue
            ? 'Overdue • ${DateFormat('MMM d').format(due)}'
            : 'Due ${DateFormat('MMM d').format(due)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 18,
            color: isOverdue ? Colors.redAccent : AppTheme.primaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(subject, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(
            dueLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOverdue ? Colors.redAccent : AppTheme.softGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final AssessmentModel assessment;
  final SchoolAdminProvider school;

  const _GradeRow({required this.assessment, required this.school});

  @override
  Widget build(BuildContext context) {
    final subject = school.subjectNameForId(assessment.subjectId) ?? 'Subject';
    final pct = assessment.percentage?.round();
    final when = assessment.publishedAt ?? assessment.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assessment.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '$subject • ${DateFormat('MMM d').format(when)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (pct != null)
            Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.softGreen)),
        ],
      ),
    );
  }
}

class _HealthTab extends StatelessWidget {
  final ChildModel child;
  final bool isDark;

  const _HealthTab({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildProvider>(
      builder: (context, childProvider, _) {
        ChildModel liveChild = child;
        for (final c in childProvider.children) {
          if (c.id == child.id) {
            liveChild = c;
            break;
          }
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            ParentHealthModulePanel(child: liveChild, isDark: isDark),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
