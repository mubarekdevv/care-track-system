/// Preconfigured academic structure (Grades 1–5) for hybrid deployments.
/// Seeded into Firestore on admin bootstrap; admin CRUD can edit afterward.
class CatalogTeacherAssignment {
  final String subjectName;
  final String teacherName;
  final String teacherEmail;
  final String subjectIcon;

  const CatalogTeacherAssignment({
    required this.subjectName,
    required this.teacherName,
    required this.teacherEmail,
    this.subjectIcon = 'menu_book',
  });
}

class CatalogGrade {
  final int level;
  final String displayName;
  final List<CatalogTeacherAssignment> subjects;

  const CatalogGrade({
    required this.level,
    required this.displayName,
    required this.subjects,
  });

  /// Single class per grade (e.g. "Grade 1", not "Grade 1-A").
  String get classSectionName => displayName;
}

class AcademicCatalog {
  AcademicCatalog._();

  static const List<CatalogGrade> grades = [
    CatalogGrade(
      level: 1,
      displayName: 'Grade 1',
      subjects: [
        CatalogTeacherAssignment(
          subjectName: 'English',
          teacherName: 'Ms. Emily Carter',
          teacherEmail: 'e.carter@school.edu',
          subjectIcon: 'translate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Mathematics',
          teacherName: 'Mr. David Brooks',
          teacherEmail: 'd.brooks@school.edu',
          subjectIcon: 'calculate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Science',
          teacherName: 'Ms. Lily Nguyen',
          teacherEmail: 'l.nguyen@school.edu',
          subjectIcon: 'science',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Art',
          teacherName: 'Mr. James Holt',
          teacherEmail: 'j.holt@school.edu',
          subjectIcon: 'palette',
        ),
      ],
    ),
    CatalogGrade(
      level: 2,
      displayName: 'Grade 2',
      subjects: [
        CatalogTeacherAssignment(
          subjectName: 'English',
          teacherName: 'Ms. Sarah Mitchell',
          teacherEmail: 's.mitchell@school.edu',
          subjectIcon: 'translate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Mathematics',
          teacherName: 'Mr. Robert Chen',
          teacherEmail: 'r.chen@school.edu',
          subjectIcon: 'calculate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Science',
          teacherName: 'Ms. Anna Rivera',
          teacherEmail: 'a.rivera@school.edu',
          subjectIcon: 'science',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Physical Education',
          teacherName: 'Coach Mark Ellis',
          teacherEmail: 'm.ellis@school.edu',
          subjectIcon: 'sports',
        ),
      ],
    ),
    CatalogGrade(
      level: 3,
      displayName: 'Grade 3',
      subjects: [
        CatalogTeacherAssignment(
          subjectName: 'Mathematics',
          teacherName: 'Mr. John Patterson',
          teacherEmail: 'j.patterson@school.edu',
          subjectIcon: 'calculate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'English',
          teacherName: 'Ms. Sarah Williams',
          teacherEmail: 's.williams@school.edu',
          subjectIcon: 'translate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Science',
          teacherName: 'Dr. Michael Torres',
          teacherEmail: 'm.torres@school.edu',
          subjectIcon: 'science',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Social Studies',
          teacherName: 'Ms. Priya Sharma',
          teacherEmail: 'p.sharma@school.edu',
          subjectIcon: 'public',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Music',
          teacherName: 'Mr. Daniel Reed',
          teacherEmail: 'd.reed@school.edu',
          subjectIcon: 'music_note',
        ),
      ],
    ),
    CatalogGrade(
      level: 4,
      displayName: 'Grade 4',
      subjects: [
        CatalogTeacherAssignment(
          subjectName: 'Mathematics',
          teacherName: 'Ms. Olivia Grant',
          teacherEmail: 'o.grant@school.edu',
          subjectIcon: 'calculate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'English',
          teacherName: 'Mr. Thomas Wright',
          teacherEmail: 't.wright@school.edu',
          subjectIcon: 'translate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Science',
          teacherName: 'Ms. Grace Kim',
          teacherEmail: 'g.kim@school.edu',
          subjectIcon: 'science',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Computer Studies',
          teacherName: 'Mr. Alex Morgan',
          teacherEmail: 'a.morgan@school.edu',
          subjectIcon: 'computer',
        ),
      ],
    ),
    CatalogGrade(
      level: 5,
      displayName: 'Grade 5',
      subjects: [
        CatalogTeacherAssignment(
          subjectName: 'Mathematics',
          teacherName: 'Mr. Henry Adams',
          teacherEmail: 'h.adams@school.edu',
          subjectIcon: 'calculate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'English',
          teacherName: 'Ms. Rachel Foster',
          teacherEmail: 'r.foster@school.edu',
          subjectIcon: 'translate',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Science',
          teacherName: 'Dr. Nina Patel',
          teacherEmail: 'n.patel@school.edu',
          subjectIcon: 'science',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Social Studies',
          teacherName: 'Mr. Chris Lambert',
          teacherEmail: 'c.lambert@school.edu',
          subjectIcon: 'public',
        ),
        CatalogTeacherAssignment(
          subjectName: 'Physical Education',
          teacherName: 'Coach Lisa Monroe',
          teacherEmail: 'l.monroe@school.edu',
          subjectIcon: 'sports',
        ),
      ],
    ),
  ];

  static CatalogGrade? byLevel(int level) {
    for (final g in grades) {
      if (g.level == level) return g;
    }
    return null;
  }

  static CatalogGrade? byDisplayName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final g in grades) {
      if (g.displayName.toLowerCase() == normalized) return g;
    }
    return null;
  }

  static int? parseGradeLevel(String gradeName) {
    final match = RegExp(r'(\d+)').firstMatch(gradeName);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static const List<CatalogTeacherAssignment> defaultCoreSubjects = [
    CatalogTeacherAssignment(
      subjectName: 'English',
      teacherName: 'Pending',
      teacherEmail: '',
      subjectIcon: 'translate',
    ),
    CatalogTeacherAssignment(
      subjectName: 'Mathematics',
      teacherName: 'Pending',
      teacherEmail: '',
      subjectIcon: 'calculate',
    ),
    CatalogTeacherAssignment(
      subjectName: 'Science',
      teacherName: 'Pending',
      teacherEmail: '',
      subjectIcon: 'science',
    ),
  ];

  static const List<CatalogTeacherAssignment> defaultUpperSubjects = [
    ...defaultCoreSubjects,
    CatalogTeacherAssignment(
      subjectName: 'Social Studies',
      teacherName: 'Pending',
      teacherEmail: '',
      subjectIcon: 'public',
    ),
  ];

  /// Template for any grade level (uses catalog when available, else defaults).
  static CatalogGrade templateForLevel(int level) {
    final existing = byLevel(level);
    if (existing != null) return existing;
    return CatalogGrade(
      level: level,
      displayName: 'Grade $level',
      subjects: level <= 5 ? defaultCoreSubjects : defaultUpperSubjects,
    );
  }
}
