import 'package:flutter/material.dart';

/// Shared layout breakpoints for responsive KidCare screens.
class AppBreakpoints {
  AppBreakpoints._();

  /// Matches the wide layout used on role selection.
  static const double medium = 680;

  /// Tablet / desktop — switch primary nav to [NavigationRail].
  static const double expanded = 840;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMediumOrWider(BuildContext context) =>
      widthOf(context) >= medium;

  static bool isExpanded(BuildContext context) => widthOf(context) >= expanded;

  static bool isCompact(BuildContext context) => !isExpanded(context);
}
