import 'package:flutter/material.dart';

import '../../core/constants/routes.dart';
import '../../core/constants/user_role.dart';
import '../../core/navigation/auth_navigation.dart';
import '../../core/theme/app_theme.dart';

/// Explains parent-first vs student-first registration before sign-up.
class RegistrationPathsScreen extends StatelessWidget {
  const RegistrationPathsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('How will you join?'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Choose the path that fits your family',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Both paths link parents and students securely. Passwords are never stored in the database.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            _PathCard(
              icon: Icons.family_restroom_rounded,
              color: AppTheme.primaryBlue,
              title: 'I\'m a parent',
              steps: const [
                'Create your parent account',
                'Add your child\'s details and enroll in a grade',
                'Share the 6-digit link code with your child',
                'Child can sign up and use the same code to connect',
              ],
              onTap: () => AuthNavigation.openRegister(context, UserRole.parent),
            ),
            const SizedBox(height: 16),
            _PathCard(
              icon: Icons.school_rounded,
              color: AppTheme.softGreen,
              title: 'I\'m a student',
              steps: const [
                'Create your student account',
                'Choose: parent enrolled me OR register on my own',
                'If parent enrolled you: enter their 6-digit code',
                'Then use the app — homework, profile, badges',
              ],
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.studentRegister,
              ),
            ),
            const SizedBox(height: 16),
            _PathCard(
              icon: Icons.groups_rounded,
              color: const Color(0xFFE2894A),
              title: 'I\'m a teacher',
              steps: const [
                'Create your teacher account',
                'Pick subjects you teach (from the school list)',
                'Admin assigns you to a grade + subject you qualify for',
              ],
              onTap: () => AuthNavigation.openRegister(context, UserRole.teacher),
            ),
            const SizedBox(height: 16),
            _PathCard(
              icon: Icons.local_hospital_rounded,
              color: const Color(0xFF9013FE),
              title: 'I\'m healthcare / clinic staff',
              steps: const [
                'Create your healthcare account',
                'Access growth charts and vaccination logs',
                'Work with families linked to the school',
              ],
              onTap: () => AuthNavigation.openOnboarding(context, UserRole.healthcare),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> steps;
  final VoidCallback onTap;

  const _PathCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.steps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: color),
                ],
              ),
              const SizedBox(height: 16),
              ...steps.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
