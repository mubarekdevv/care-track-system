import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/parent_demo_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/child_model.dart';
import '../../models/parent_insights.dart';
import '../../widgets/dashboard/simple_bar_chart.dart';
import '../../widgets/parent/child_photo_avatar.dart';

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
    _child ??= ModalRoute.of(context)?.settings.arguments as ChildModel?;
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

  @override
  Widget build(BuildContext context) {
    final child = _child;
    if (child == null) {
      return const Scaffold(body: Center(child: Text('Child not found')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grades = ParentDemoData.gradesFor(child);
    final events = ParentDemoData.timelineFor(child);
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
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
                        ChildPhotoAvatar(
                          child: child,
                          radius: 36,
                          borderColor: Colors.white,
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
                                '${child.age} years • ${ParentDemoData.gradeForAge(child.age)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap photo to update',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: isDark ? Colors.grey[400] : AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(text: 'Timeline'),
                Tab(text: 'Academics'),
                Tab(text: 'Health'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TimelineTab(events: events, dateFmt: dateFmt, isDark: isDark),
            _AcademicsTab(grades: grades, isDark: isDark),
            _HealthTab(child: child, events: events, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final List<TimelineEvent> events;
  final DateFormat dateFmt;
  final bool isDark;

  const _TimelineTab({
    required this.events,
    required this.dateFmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final color = ParentDemoData.colorForEventType(event.type);
        final isLast = index == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Icon(event.icon, color: color, size: 18),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFmt.format(event.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AcademicsTab extends StatelessWidget {
  final List<SubjectGrade> grades;
  final bool isDark;

  const _AcademicsTab({required this.grades, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final avg = grades.map((g) => g.score).reduce((a, b) => a + b) / grades.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _SectionCard(
          isDark: isDark,
          title: 'Subject Performance',
          child: SimpleBarChart(
            labels: grades.map((g) => g.subject).toList(),
            values: grades.map((g) => g.score).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          isDark: isDark,
          title: 'Overall Average',
          child: Row(
            children: [
              Text(
                '${avg.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+8% vs last term',
                  style: TextStyle(
                    color: AppTheme.softGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...grades.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SectionCard(
              isDark: isDark,
              title: g.subject,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${g.score.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    g.change >= 0 ? '+${g.change.toInt()}% improvement' : '${g.change.toInt()}% change',
                    style: TextStyle(
                      fontSize: 12,
                      color: g.change >= 0 ? AppTheme.softGreen : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthTab extends StatelessWidget {
  final ChildModel child;
  final List<TimelineEvent> events;
  final bool isDark;

  const _HealthTab({
    required this.child,
    required this.events,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final healthEvents = events.where((e) => e.type == TimelineEventType.health).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _SectionCard(
          isDark: isDark,
          title: 'Vaccination Status',
          child: child.vaccinations.isEmpty
              ? const Text(
                  'No vaccines logged yet. Update the profile from Add Child.',
                  style: TextStyle(height: 1.4, color: AppTheme.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: child.vaccinations
                      .map(
                        (v) => Chip(
                          label: Text(v, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.softGreen.withValues(alpha: 0.12),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          isDark: isDark,
          title: 'Recent Health Events',
          child: Column(
            children: healthEvents
                .map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(e.icon, color: AppTheme.softGreen),
                    title: Text(
                      e.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(e.description, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
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
