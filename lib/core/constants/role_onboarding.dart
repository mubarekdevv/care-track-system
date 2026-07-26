import 'package:flutter/material.dart';
import 'auth_assets.dart';
import 'user_role.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final String imageAsset;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.imageAsset,
  });
}

/// Role-specific onboarding copy and visuals shown before registration.
class RoleOnboarding {
  RoleOnboarding._();

  static String heroAssetFor(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return AuthAssets.registerHeroForRole('Teacher');
      case UserRole.healthcare:
        return AuthAssets.registerHeroForRole('Healthcare');
      case UserRole.child:
        return AuthAssets.registerHeroForRole('Child');
      case UserRole.parent:
        return AuthAssets.registerHero;
      case UserRole.admin:
        return AuthAssets.featureSecure;
    }
  }

  static String welcomeTitleFor(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return 'Welcome, Parent';
      case UserRole.teacher:
        return 'Welcome, Teacher';
      case UserRole.child:
        return 'Welcome, Explorer';
      case UserRole.healthcare:
        return 'Welcome, Care Provider';
      case UserRole.admin:
        return 'Welcome, Admin';
    }
  }

  static String welcomeSubtitleFor(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return 'Everything you need to support your child — academics, health, and shopping in one place.';
      case UserRole.teacher:
        return 'Manage your classroom, track progress, and keep parents in the loop effortlessly.';
      case UserRole.child:
        return 'Your personal hub for tasks, badges, and daily adventures at school.';
      case UserRole.healthcare:
        return 'Professional tools for pediatric records, vaccinations, and clinic visits.';
      case UserRole.admin:
        return 'Set up your school structure — grades, classes, subjects, and staff.';
    }
  }

  static List<OnboardingSlide> slidesFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          OnboardingSlide(
            title: 'School Setup',
            description:
                'Create grade levels, class sections, and subjects for your school.',
            icon: Icons.apartment_rounded,
            imageAsset: AuthAssets.featureSecure,
          ),
          OnboardingSlide(
            title: 'Assign Teachers',
            description:
                'Link teachers to classes and subjects so parents get the right contacts automatically.',
            icon: Icons.groups_rounded,
            imageAsset: AuthAssets.featureTeacher,
          ),
          OnboardingSlide(
            title: 'Ready for Families',
            description:
                'Once setup is done, parents can enroll students and the ecosystem goes live.',
            icon: Icons.check_circle_rounded,
            imageAsset: AuthAssets.featureParent,
          ),
        ];
      case UserRole.parent:
        return const [
          OnboardingSlide(
            title: 'Child Overview',
            description:
                'See profiles, attendance, grades, and health updates in one calming dashboard.',
            icon: Icons.family_restroom_rounded,
            imageAsset: AuthAssets.featureParent,
          ),
          OnboardingSlide(
            title: 'Smart Alerts',
            description:
                'Get notified about homework, checkups, billing, and school announcements instantly.',
            icon: Icons.notifications_active_rounded,
            imageAsset: AuthAssets.featureSecure,
          ),
          OnboardingSlide(
            title: 'Family Shop',
            description:
                'Shop books, uniforms, and health essentials with recommendations tailored to your child.',
            icon: Icons.storefront_rounded,
            imageAsset: AuthAssets.featureChild,
          ),
        ];
      case UserRole.teacher:
        return const [
          OnboardingSlide(
            title: 'Classroom Hub',
            description:
                'View your student roster, mark attendance, and submit grades from anywhere.',
            icon: Icons.school_rounded,
            imageAsset: AuthAssets.featureTeacher,
          ),
          OnboardingSlide(
            title: 'Performance Insights',
            description:
                'Spot trends early with analytics on attendance, homework, and subject progress.',
            icon: Icons.insights_rounded,
            imageAsset: AuthAssets.featureSecure,
          ),
          OnboardingSlide(
            title: 'Parent Communication',
            description:
                'Send updates and messages so families stay informed and engaged.',
            icon: Icons.chat_bubble_rounded,
            imageAsset: AuthAssets.featureParent,
          ),
        ];
      case UserRole.child:
        return const [
          OnboardingSlide(
            title: 'Your Daily Quest',
            description:
                'See assignments, fun tasks, and your schedule with playful icons and colors.',
            icon: Icons.emoji_events_rounded,
            imageAsset: AuthAssets.featureChild,
          ),
          OnboardingSlide(
            title: 'Earn Badges',
            description:
                'Complete homework and activities to unlock rewards and level up your progress.',
            icon: Icons.military_tech_rounded,
            imageAsset: AuthAssets.featureTeacher,
          ),
          OnboardingSlide(
            title: 'Stay on Track',
            description:
                'Never miss a class or activity with a simple, visual daily timeline.',
            icon: Icons.calendar_today_rounded,
            imageAsset: AuthAssets.featureSecure,
          ),
        ];
      case UserRole.healthcare:
        return const [
          OnboardingSlide(
            title: 'Patient Directory',
            description:
                'Search pediatric profiles, growth metrics, and immunization history in seconds.',
            icon: Icons.folder_shared_rounded,
            imageAsset: AuthAssets.featureHealthcare,
          ),
          OnboardingSlide(
            title: 'Vaccination Registry',
            description:
                'Log doses, track boosters, and keep clinic records accurate and compliant.',
            icon: Icons.vaccines_rounded,
            imageAsset: AuthAssets.featureSecure,
          ),
          OnboardingSlide(
            title: 'Clinic Schedule',
            description:
                'Manage appointments, urgent alerts, and visit notes from your healthcare dashboard.',
            icon: Icons.event_available_rounded,
            imageAsset: AuthAssets.featureParent,
          ),
        ];
    }
  }
}
