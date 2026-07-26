import 'package:flutter/material.dart';

class RoleStyles {
  static const Map<String, Map<String, dynamic>> roles = {
    'Parent': {
      'icon': Icons.family_restroom_rounded,
      'gradient': LinearGradient(
        colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'accent': Color(0xFF4A90E2),
    },
    'Teacher': {
      'icon': Icons.school_rounded,
      'gradient': LinearGradient(
        colors: [Color(0xFF7ED321), Color(0xFF5CA216)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'accent': Color(0xFF7ED321),
    },
    'Healthcare': {
      'icon': Icons.medical_services_rounded,
      'gradient': LinearGradient(
        colors: [Color(0xFFE2894A), Color(0xFFBD7135)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'accent': Color(0xFFE2894A),
    },
    'Child': {
      'icon': Icons.child_care_rounded,
      'gradient': LinearGradient(
        colors: [Color(0xFF9013FE), Color(0xFF700CB5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'accent': Color(0xFF9013FE),
    },
    'Admin': {
      'icon': Icons.admin_panel_settings_rounded,
      'gradient': LinearGradient(
        colors: [Color(0xFF374151), Color(0xFF1F2937)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'accent': Color(0xFF374151),
    },
  };

  static Map<String, dynamic> forRole(String role) {
    return roles[role] ?? roles['Parent']!;
  }
}
