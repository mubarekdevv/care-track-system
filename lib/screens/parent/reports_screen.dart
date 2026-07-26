import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:provider/provider.dart';



import '../../core/academic/enrollment_display.dart';

import '../../core/domain/domain_enums.dart';

import '../../core/theme/app_theme.dart';

import '../../data/firestore/firestore_academic_repository.dart';

import '../../models/academic_models.dart';

import '../../models/child_model.dart';

import '../../providers/child_provider.dart';

import '../../providers/school_admin_provider.dart';

import '../../widgets/profile/kidcare_avatar_image.dart';



class ReportsScreen extends StatelessWidget {

  const ReportsScreen({super.key});



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final children = Provider.of<ChildProvider>(context).children;



    return Scaffold(

      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,

      appBar: AppBar(

        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),

        centerTitle: false,

      ),

      body: children.isEmpty

          ? Center(

              child: Padding(

                padding: const EdgeInsets.all(32),

                child: Text(

                  'Add a child profile to view attendance and grades from Firestore.',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,

                    height: 1.5,

                  ),

                ),

              ),

            )

          : ListView(

              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),

              physics: const BouncingScrollPhysics(),

              children: [

                _SummaryBanner(isDark: isDark, childCount: children.length),

                const SizedBox(height: 16),

                ...children.map(

                  (child) => Padding(

                    padding: const EdgeInsets.only(bottom: 12),

                    child: _ChildReportCard(child: child, isDark: isDark),

                  ),

                ),

              ],

            ),

    );

  }

}



class _SummaryBanner extends StatelessWidget {

  final bool isDark;

  final int childCount;



  const _SummaryBanner({required this.isDark, required this.childCount});



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          colors: [AppTheme.softGreen, Color(0xFF5CA216)],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),

        borderRadius: BorderRadius.circular(20),

      ),

      child: Row(

        children: [

          const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text(

                  'Live school reports',

                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),

                ),

                const SizedBox(height: 4),

                Text(

                  'Attendance + published grades for $childCount ${childCount == 1 ? 'child' : 'children'}',

                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}



class _ChildReportCard extends StatelessWidget {

  final ChildModel child;

  final bool isDark;



  const _ChildReportCard({required this.child, required this.isDark});

  @override

  Widget build(BuildContext context) {

    final school = context.watch<SchoolAdminProvider>();

    final classLabel = EnrollmentDisplay.classOrGradeLabel(
      school,
      child.classRoomId,
      gradeLevelId: child.gradeLevelId,
    );



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

              KidCareAvatarImage(

                photoUrl: child.imageUrl,

                name: child.name,

                radius: 22,

                accent: AppTheme.primaryBlue,

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),

                    Text(

                      child.classRoomId != null ? classLabel : 'Not enrolled in a grade yet',

                      style: TextStyle(

                        fontSize: 12,

                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),

          if (child.classRoomId == null)

            Text(

              'Enroll this child in a grade to see attendance and teacher grades.',

              style: TextStyle(

                fontSize: 12,

                height: 1.4,

                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,

              ),

            )

          else ...[

            _LiveReportSection(studentId: child.id, isDark: isDark, school: school),

          ],

        ],

      ),

    );

  }

}



class _LiveReportSection extends StatelessWidget {

  final String studentId;

  final bool isDark;

  final SchoolAdminProvider school;



  const _LiveReportSection({

    required this.studentId,

    required this.isDark,

    required this.school,

  });



  @override

  Widget build(BuildContext context) {

    final repo = FirestoreAcademicRepository();



    return StreamBuilder<List<AssessmentModel>>(

      stream: repo.watchPublishedAssessmentsForStudent(studentId),

      builder: (context, gradeSnap) {

        return StreamBuilder<List<AttendanceRecordModel>>(

          stream: repo.watchRecentAttendanceForStudent(studentId),

          builder: (context, attSnap) {

            if (gradeSnap.connectionState == ConnectionState.waiting &&

                attSnap.connectionState == ConnectionState.waiting) {

              return const LinearProgressIndicator(minHeight: 2);

            }



            final assessments = gradeSnap.data ?? [];

            final attendance = attSnap.data ?? [];

            final avg = _averagePercent(assessments);

            final presentDays = attendance

                .where((a) =>

                    a.status == AttendanceStatus.present ||

                    a.status == AttendanceStatus.late ||

                    a.status == AttendanceStatus.excused)

                .length;



            return Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    _StatPill(

                      label: 'Avg grade',

                      value: avg != null ? '$avg%' : '—',

                      color: AppTheme.softGreen,

                      isDark: isDark,

                    ),

                    const SizedBox(width: 8),

                    _StatPill(

                      label: 'Present (recent)',

                      value: attendance.isEmpty ? '—' : '$presentDays/${attendance.length}',

                      color: AppTheme.primaryBlue,

                      isDark: isDark,

                    ),

                  ],

                ),

                if (assessments.isNotEmpty) ...[

                  const SizedBox(height: 14),

                  Text(

                    'Grades',

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 13,

                      color: isDark ? Colors.white : AppTheme.textPrimary,

                    ),

                  ),

                  const SizedBox(height: 8),

                  ...assessments.take(6).map((a) => _GradeRow(assessment: a, school: school)),

                ],

                if (attendance.isNotEmpty) ...[

                  const SizedBox(height: 14),

                  Text(

                    'Recent attendance',

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 13,

                      color: isDark ? Colors.white : AppTheme.textPrimary,

                    ),

                  ),

                  const SizedBox(height: 8),

                  ...attendance.take(5).map((a) => _AttendanceRow(record: a)),

                ],

                if (assessments.isEmpty && attendance.isEmpty)

                  Text(

                    'No published data yet. Teachers mark attendance and publish homework grades.',

                    style: TextStyle(

                      fontSize: 12,

                      height: 1.4,

                      color: isDark ? Colors.grey[400] : AppTheme.textSecondary,

                    ),

                  ),

              ],

            );

          },

        );

      },

    );

  }



  int? _averagePercent(List<AssessmentModel> list) {

    if (list.isEmpty) return null;

    final pcts = list.map((a) => a.percentage).whereType<double>().toList();

    if (pcts.isEmpty) return null;

    return (pcts.reduce((a, b) => a + b) / pcts.length).round();

  }

}



class _StatPill extends StatelessWidget {

  final String label;

  final String value;

  final Color color;

  final bool isDark;



  const _StatPill({

    required this.label,

    required this.value,

    required this.color,

    required this.isDark,

  });



  @override

  Widget build(BuildContext context) {

    return Expanded(

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        decoration: BoxDecoration(

          color: color.withValues(alpha: 0.1),

          borderRadius: BorderRadius.circular(12),

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : AppTheme.textSecondary)),

            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),

          ],

        ),

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



    return Padding(

      padding: const EdgeInsets.only(bottom: 6),

      child: Row(

        children: [

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(assessment.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),

                Text(subject, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),

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



class _AttendanceRow extends StatelessWidget {

  final AttendanceRecordModel record;



  const _AttendanceRow({required this.record});



  @override

  Widget build(BuildContext context) {

    final date = DateFormat('MMM d').format(record.date);

    final (label, color) = switch (record.status) {

      AttendanceStatus.present => ('Present', AppTheme.softGreen),

      AttendanceStatus.late => ('Late', Colors.orange),

      AttendanceStatus.excused => ('Excused', AppTheme.primaryBlue),

      AttendanceStatus.absent => ('Absent', Colors.redAccent),

    };



    return Padding(

      padding: const EdgeInsets.only(bottom: 4),

      child: Row(

        children: [

          SizedBox(width: 72, child: Text(date, style: const TextStyle(fontSize: 12))),

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

            decoration: BoxDecoration(

              color: color.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(6),

            ),

            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),

          ),

        ],

      ),

    );

  }

}


