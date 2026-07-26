import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/add_child_display_mode.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/parent_preferences_provider.dart';

class AddChildDisplaySetting extends StatelessWidget {
  const AddChildDisplaySetting({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<ParentPreferencesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.child_care_rounded, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add child button',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to add a new child on your home screen.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...AddChildDisplayMode.values.map((mode) {
            final selected = prefs.addChildDisplayMode == mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected
                    ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08)
                    : (isDark ? AppTheme.darkBackground : AppTheme.warmNeutral),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => prefs.setAddChildDisplayMode(mode),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryBlue.withValues(alpha: 0.45)
                            : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mode.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
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
            );
          }),
        ],
      ),
    );
  }
}
