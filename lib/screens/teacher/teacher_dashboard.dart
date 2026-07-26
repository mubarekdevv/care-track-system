import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/profile/user_profile_avatar.dart';
import '../../widgets/teacher/grade_entry_sheet.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: const [
          _TeacherHomeTab(),
          _TeacherAttendanceTab(),
          _TeacherHomeworkTab(),
          _TeacherMessagesTab(),
          _TeacherProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
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
      ),
    );
  }
}

// ==================== OVERVIEW TAB ====================
class _TeacherHomeTab extends StatelessWidget {
  const _TeacherHomeTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildWelcomeHeader(context, user?.fullName ?? 'Educator', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildQuickStats(isDark),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Today\'s Class Schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final list = [
                    ('08:30 AM', 'Mathematics Basics', 'Grade 3-A', Icons.functions_rounded, const Color(0xFF4A90E2)),
                    ('10:00 AM', 'English Grammar', 'Grade 3-A', Icons.menu_book_rounded, const Color(0xFF7ED321)),
                    ('11:30 AM', 'Science & Environment', 'Grade 3-A', Icons.biotech_rounded, const Color(0xFF9013FE)),
                    ('01:30 PM', 'Creative Arts', 'Grade 3-A', Icons.palette_rounded, const Color(0xFFE2894A)),
                  ];
                  final item = list[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ClassScheduleCard(
                      time: item.$1,
                      title: item.$2,
                      grade: item.$3,
                      icon: item.$4,
                      accentColor: item.$5,
                      isDark: isDark,
                    ),
                  );
                },
                childCount: 4,
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  'Recent Active Tasks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  children: [
                    _TaskTile(
                      title: 'Grading Science Homework',
                      subtitle: '18 of 24 sheets submitted',
                      progress: 0.75,
                      accent: const Color(0xFF9013FE),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _TaskTile(
                      title: 'Weekly Attendance Report',
                      subtitle: 'Needs review and validation',
                      progress: 0.90,
                      accent: const Color(0xFF7ED321),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String name, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7ED321), Color(0xFF5CA216)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7ED321).withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher Center',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hello, $name',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const UserProfileAvatar(radius: 28, editable: false, showGradientRing: true),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Class Grade: 3-A • Classroom 104',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    final stats = [
      ('Present', '92%', 'Attendance today', const Color(0xFF7ED321), Icons.people_rounded),
      ('Homework', '4 Active', 'Due this week', const Color(0xFF4A90E2), Icons.assignment_rounded),
      ('Alerts', '2 Urgent', 'Parent inquiries', const Color(0xFFE2894A), Icons.warning_amber_rounded),
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

// ==================== ATTENDANCE TAB ====================
class _TeacherAttendanceTab extends StatefulWidget {
  const _TeacherAttendanceTab();

  @override
  State<_TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<_TeacherAttendanceTab> {
  final List<Map<String, dynamic>> _students = [
    {'name': 'Emma Watson', 'present': true, 'age': 9, 'code': 'S101'},
    {'name': 'Liam Neeson', 'present': true, 'age': 8, 'code': 'S102'},
    {'name': 'Olivia Rodrigo', 'present': false, 'age': 9, 'code': 'S103'},
    {'name': 'Noah Centineo', 'present': true, 'age': 9, 'code': 'S104'},
    {'name': 'Sophia Loren', 'present': true, 'age': 8, 'code': 'S105'},
    {'name': 'Jackson Pollock', 'present': true, 'age': 9, 'code': 'S106'},
    {'name': 'Ava DuVernay', 'present': false, 'age': 8, 'code': 'S107'},
    {'name': 'Lucas Hedges', 'present': true, 'age': 9, 'code': 'S108'},
  ];

  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    return _students
        .where((s) => s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  int get _presentCount => _students.where((s) => s['present'] == true).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = _filteredStudents;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Attendance Registry', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
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
                      border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Today\'s Ratio', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                '$_presentCount / ${_students.length} Present',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            '${((_presentCount / _students.length) * 100).toInt()}% Rate',
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
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
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
                        'No students found.',
                        style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = list[index];
                        final isPresent = student['present'] as bool;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPresent
                                  ? const Color(0xFF7ED321).withValues(alpha: 0.3)
                                  : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isPresent
                                    ? const Color(0xFF7ED321).withValues(alpha: 0.12)
                                    : Colors.redAccent.withValues(alpha: 0.1),
                                child: Text(
                                  student['name'].toString()[0],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPresent ? const Color(0xFF7ED321) : Colors.redAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'].toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'ID: ${student['code']} • ${student['age']} years old',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isPresent,
                                activeThumbColor: const Color(0xFF7ED321),
                                activeTrackColor: const Color(0xFF7ED321).withValues(alpha: 0.2),
                                onChanged: (value) {
                                  setState(() {
                                    student['present'] = value;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${student['name']} marked ${value ? 'Present' : 'Absent'}'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }
}

// ==================== HOMEWORK TAB ====================
class _TeacherHomeworkTab extends StatefulWidget {
  const _TeacherHomeworkTab();

  @override
  State<_TeacherHomeworkTab> createState() => _TeacherHomeworkTabState();
}

class _TeacherHomeworkTabState extends State<_TeacherHomeworkTab> {
  final List<Map<String, dynamic>> _homeworks = [
    {
      'title': 'Math: Fractions & Divisions',
      'subject': 'Mathematics',
      'dueDate': 'May 29, 2026',
      'status': 'Active',
      'grade': 'Grade 3-A',
      'submissions': '18 / 24'
    },
    {
      'title': 'English Grammar: Verb Tenses',
      'subject': 'English Language',
      'dueDate': 'May 30, 2026',
      'status': 'Active',
      'grade': 'Grade 3-A',
      'submissions': '12 / 24'
    },
    {
      'title': 'Science: Planet Earth Project',
      'subject': 'Natural Sciences',
      'dueDate': 'June 02, 2026',
      'status': 'Active',
      'grade': 'Grade 3-A',
      'submissions': '0 / 24'
    },
  ];

  final _titleController = TextEditingController();
  String _selectedSubject = 'Mathematics';
  DateTime? _dueDate;

  void _showAddAssignmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _titleController.clear();
    _dueDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Assignment',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Assignment Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Science: Solar System Essay',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Mathematics', 'English Language', 'Natural Sciences', 'Creative Arts']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => _selectedSubject = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setSheetState(() => _dueDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: isDark ? Colors.grey[400] : AppTheme.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _dueDate != null
                                ? DateFormat('MMMM dd, yyyy').format(_dueDate!)
                                : 'Select Due Date',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_titleController.text.trim().isEmpty || _dueDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please complete all assignment details')),
                          );
                          return;
                        }
                        setState(() {
                          _homeworks.insert(0, {
                            'title': _titleController.text.trim(),
                            'subject': _selectedSubject,
                            'dueDate': DateFormat('MMMM dd, yyyy').format(_dueDate!),
                            'status': 'Active',
                            'grade': 'Grade 3-A',
                            'submissions': '0 / 24'
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Assignment added successfully!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.all(12),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9013FE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Publish Assignment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Homework & Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssignmentSheet,
        backgroundColor: const Color(0xFF9013FE),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Assign Homework', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: _homeworks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final hw = _homeworks[index];
          final subjectColor = switch (hw['subject']) {
            'Mathematics' => const Color(0xFF4A90E2),
            'English Language' => const Color(0xFF7ED321),
            'Natural Sciences' => const Color(0xFF9013FE),
            _ => const Color(0xFFE2894A),
          };

          return Material(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => GradeEntrySheet.show(
                context,
                assignmentTitle: hw['title'] as String,
                subject: hw['subject'] as String,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: subjectColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hw['subject'] as String,
                              style: TextStyle(color: subjectColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hw['status'] as String,
                              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hw['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Class: ${hw['grade']}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Due: ${hw['dueDate']}',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Icon(Icons.grade_rounded, size: 14, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to grade',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== MESSAGES TAB ====================
class _TeacherMessagesTab extends StatefulWidget {
  const _TeacherMessagesTab();

  @override
  State<_TeacherMessagesTab> createState() => _TeacherMessagesTabState();
}

class _TeacherMessagesTabState extends State<_TeacherMessagesTab> {
  final List<Map<String, dynamic>> _messages = [
    {
      'parent': 'Helen Watson (Emma\'s Mom)',
      'preview': 'Sure teacher, Emma will review her division rules tonight!',
      'time': '10:45 AM',
      'unread': true,
    },
    {
      'parent': 'David Rodrigo (Olivia\'s Dad)',
      'preview': 'Hello, Olivia will be absent today due to dental cleaning.',
      'time': '08:12 AM',
      'unread': false,
    },
    {
      'parent': 'Jane Loren (Sophia\'s Mom)',
      'preview': 'Excellent! Thanks for the updates on weekly badges.',
      'time': 'Yesterday',
      'unread': false,
    },
  ];

  final _textController = TextEditingController();

  void _sendMessageSimulation(String parent) {
    if (_textController.text.trim().isEmpty) return;
    final text = _textController.text.trim();
    setState(() {
      for (var msg in _messages) {
        if (msg['parent'] == parent) {
          msg['preview'] = 'You: $text';
          msg['time'] = 'Just now';
          msg['unread'] = false;
        }
      }
    });
    _textController.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message sent to parent'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _openChatSheet(String parentName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    parentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This simulates messaging channels between teachers and parents. All logs are securely cryptographed.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  suffixIcon: IconButton(
                    onPressed: () => _sendMessageSimulation(parentName),
                    icon: const Icon(Icons.send_rounded, color: AppTheme.primaryBlue),
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Inbox Communication', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return InkWell(
            onTap: () => _openChatSheet(msg['parent']),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: msg['unread']
                      ? AppTheme.primaryBlue.withValues(alpha: 0.35)
                      : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                  width: msg['unread'] ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              msg['parent'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: msg['unread'] ? AppTheme.primaryBlue : (isDark ? Colors.white : AppTheme.textPrimary),
                              ),
                            ),
                            Text(
                              msg['time'],
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['preview'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: msg['unread']
                                ? (isDark ? Colors.white : AppTheme.textPrimary)
                                : (isDark ? Colors.grey[400] : AppTheme.textSecondary),
                            fontWeight: msg['unread'] ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== PROFILE TAB ====================
class _TeacherProfileTab extends StatelessWidget {
  const _TeacherProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(title: const Text('Profile Settings')),
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
            child: const Column(
              children: [
                _ProfileStatRow(label: 'School Unit', value: 'North Academy Center'),
                Divider(),
                _ProfileStatRow(label: 'Class Assignment', value: 'Grade 3-A'),
                Divider(),
                _ProfileStatRow(label: 'Room Assignment', value: 'Room 104'),
              ],
            ),
          ),
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
