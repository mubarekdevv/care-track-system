import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/admin/admin_overview_panel.dart';
import '../../widgets/admin/admin_profile_tab.dart';
import '../../widgets/admin/admin_shell_header.dart';
import 'admin_governance_tab.dart';
import 'admin_management_tabs.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  Future<void> _editSchoolName(BuildContext context, SchoolAdminProvider admin) async {
    final controller = TextEditingController(text: admin.school?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('School name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'e.g. Bisrat Academy',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final saved = await admin.updateSchoolName(controller.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'School name updated.' : admin.error ?? 'Could not save.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: ThemeHelpers.pageBackground(context),
      appBar: AdminShellHeader(
        admin: admin,
        onEditSchool: () => _editSchoolName(context, admin),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          AdminOverviewPanel(
            schoolName: admin.school?.name,
            userName: user?.fullName,
            onEditSchoolName: () => _editSchoolName(context, admin),
          ),
          const AdminGradesAndSectionsTab(),
          const AdminSubjectsTab(),
          const AdminTeachersTab(),
          const AdminGovernanceTab(),
          const AdminProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers_rounded),
            label: 'Grades',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Staff',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Admins',
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
