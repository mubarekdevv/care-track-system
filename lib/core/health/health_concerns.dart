import 'package:flutter/material.dart';

/// Catalog of health areas parents can select for doctor follow-up matching.
class HealthConcernOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const HealthConcernOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

class HealthConcerns {
  HealthConcerns._();

  static const none = 'general_wellness';

  static const List<HealthConcernOption> catalog = [
    HealthConcernOption(
      id: 'general_wellness',
      label: 'General wellness',
      description: 'Routine checkups and growth monitoring',
      icon: Icons.health_and_safety_outlined,
    ),
    HealthConcernOption(
      id: 'psychology',
      label: 'Psychology / mental health',
      description: 'Anxiety, ADHD, counseling, emotional support',
      icon: Icons.psychology_outlined,
    ),
    HealthConcernOption(
      id: 'disability_support',
      label: 'Disability support',
      description: 'Physical or developmental support plans',
      icon: Icons.accessible_outlined,
    ),
    HealthConcernOption(
      id: 'chronic_condition',
      label: 'Chronic condition',
      description: 'Asthma, diabetes, epilepsy, ongoing treatment',
      icon: Icons.monitor_heart_outlined,
    ),
    HealthConcernOption(
      id: 'nutrition',
      label: 'Nutrition & diet',
      description: 'Weight, allergies, eating plans',
      icon: Icons.restaurant_outlined,
    ),
    HealthConcernOption(
      id: 'speech_therapy',
      label: 'Speech & language',
      description: 'Speech delay, communication therapy',
      icon: Icons.record_voice_over_outlined,
    ),
  ];

  static HealthConcernOption? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final item in catalog) {
      if (item.id == id) return item;
    }
    return null;
  }

  static String labelsForIds(List<String> ids) {
    if (ids.isEmpty) return 'No follow-up selected';
    return ids
        .map((id) => byId(id)?.label ?? id)
        .join(', ');
  }

  /// Options enabled for this school (empty school list = full catalog).
  static List<HealthConcernOption> forSchool(List<String> enabledIds) {
    if (enabledIds.isEmpty) return catalog;
    return catalog.where((c) => enabledIds.contains(c.id)).toList();
  }

  /// Parent/doctor pickers — excludes general wellness-only unless enabled.
  static List<HealthConcernOption> clinicalForSchool(List<String> enabledIds) {
    return forSchool(enabledIds).where((c) => c.id != none).toList();
  }
}
