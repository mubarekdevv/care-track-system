import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/profile/user_profile_avatar.dart';

class HealthcareDashboard extends StatefulWidget {
  const HealthcareDashboard({super.key});

  @override
  State<HealthcareDashboard> createState() => _HealthcareDashboardState();
}

class _HealthcareDashboardState extends State<HealthcareDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: const [
          _HealthcareHomeTab(),
          _HealthcarePatientsTab(),
          _HealthcareAppointmentsTab(),
          _HealthcareProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.healing_outlined),
            selectedIcon: Icon(Icons.healing_rounded),
            label: 'Home Center',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared_rounded),
            label: 'Directory',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Credentials',
          ),
        ],
      ),
    );
  }
}

// ==================== PATIENTS DATABASE ====================
class _Patient {
  final String id;
  final String name;
  final int age;
  final double latestHeight; // in cm
  final double latestWeight; // in kg
  final List<String> vaccines;
  final String lastCheckup;

  _Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.latestHeight,
    required this.latestWeight,
    required this.vaccines,
    required this.lastCheckup,
  });
}

class _HealthcareData {
  static List<_Patient> patients = [
    _Patient(
      id: 'P001',
      name: 'Emma Watson',
      age: 9,
      latestHeight: 132.5,
      latestWeight: 28.4,
      vaccines: ['Polio (IPV) - Dose 3', 'MMR - Dose 1', 'Hepatitis B'],
      lastCheckup: 'April 14, 2026',
    ),
    _Patient(
      id: 'P002',
      name: 'Liam Neeson',
      age: 8,
      latestHeight: 126.0,
      latestWeight: 24.8,
      vaccines: ['Polio (IPV) - Dose 2', 'MMR - Dose 1'],
      lastCheckup: 'May 02, 2026',
    ),
    _Patient(
      id: 'P003',
      name: 'Olivia Rodrigo',
      age: 9,
      latestHeight: 135.2,
      latestWeight: 30.1,
      vaccines: ['Polio (IPV) - Dose 3', 'MMR - Dose 2', 'Hepatitis B', 'DTaP - Dose 4'],
      lastCheckup: 'May 20, 2026',
    ),
    _Patient(
      id: 'P004',
      name: 'Noah Centineo',
      age: 9,
      latestHeight: 131.0,
      latestWeight: 27.5,
      vaccines: ['Polio (IPV) - Dose 3', 'Hepatitis B'],
      lastCheckup: 'May 10, 2026',
    ),
  ];
}

// ==================== HOME TAB ====================
class _HealthcareHomeTab extends StatelessWidget {
  const _HealthcareHomeTab();

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
              child: _buildWelcomeHeader(context, user?.fullName ?? 'Healthcare Professional', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildClinicStats(isDark),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Today\'s Hospital Appointments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final list = [
                    ('09:00 AM', 'Emma Watson', 'Annual Pediatric Checkup', Icons.favorite_rounded, const Color(0xFFE2894A)),
                    ('10:30 AM', 'Noah Centineo', 'Flu Vaccine Shot', Icons.vaccines_rounded, const Color(0xFF4A90E2)),
                    ('02:00 PM', 'Olivia Rodrigo', 'Vision & Hearing Test', Icons.remove_red_eye_rounded, const Color(0xFF7ED321)),
                  ];
                  final item = list[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
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
                              color: item.$5.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(item.$4, color: item.$5, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$2,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.$3} • ${item.$1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
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
                childCount: 3,
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  'Urgent Clinical Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vaccine Supply Alert',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Measles/MMR booster doses are running low in Room 4.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String name, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE2894A), Color(0xFFBD7135)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE2894A).withValues(alpha: 0.25),
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
                        'Healthcare Center',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hello, $name',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
                'Metro Pediatrics Clinic • Room 402',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicStats(bool isDark) {
    final stats = [
      ('Patients', '14 Active', 'Under your watch', const Color(0xFFE2894A), Icons.groups_rounded),
      ('Vaccines', '8 Administered', 'This week total', const Color(0xFF4A90E2), Icons.vaccines_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: s == stats.first ? 10 : 0,
                left: s == stats.last ? 10 : 0,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(s.$5, color: s.$4, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    s.$2,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    s.$3,
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==================== PATIENTS DIRECTORY TAB ====================
class _HealthcarePatientsTab extends StatefulWidget {
  const _HealthcarePatientsTab();

  @override
  State<_HealthcarePatientsTab> createState() => _HealthcarePatientsTabState();
}

class _HealthcarePatientsTabState extends State<_HealthcarePatientsTab> {
  String _searchQuery = '';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _vaccineController = TextEditingController();

  List<_Patient> get _filteredPatients {
    if (_searchQuery.trim().isEmpty) return _HealthcareData.patients;
    return _HealthcareData.patients
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _openGrowthSheet(_Patient patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _heightController.text = patient.latestHeight.toString();
    _weightController.text = patient.latestWeight.toString();

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
                    'Growth Tracker - ${patient.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Patient Height (cm)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 132.5',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Patient Weight (kg)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 28.4',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final h = double.tryParse(_heightController.text);
                    final w = double.tryParse(_weightController.text);
                    if (h == null || w == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid height and weight values')),
                      );
                      return;
                    }
                    setState(() {
                      // Update growth logs in memory
                      final idx = _HealthcareData.patients.indexWhere((p) => p.id == patient.id);
                      if (idx != -1) {
                        _HealthcareData.patients[idx] = _Patient(
                          id: patient.id,
                          name: patient.name,
                          age: patient.age,
                          latestHeight: h,
                          latestWeight: w,
                          vaccines: patient.vaccines,
                          lastCheckup: DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                        );
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated growth metrics for ${patient.name}!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(12),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2894A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Update Growth Logs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openVaccineSheet(_Patient patient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _vaccineController.clear();

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
                    'Immunization Registry - ${patient.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Administered Vaccines:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (patient.vaccines.isEmpty)
                const Text('No vaccines registered yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: patient.vaccines.map((vax) {
                    return Chip(
                      label: Text(vax, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF4A90E2).withValues(alpha: 0.12),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              const Text('Administer New Vaccine', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _vaccineController,
                decoration: InputDecoration(
                  hintText: 'e.g. Polio (IPV) - Booster 1',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final vaxName = _vaccineController.text.trim();
                    if (vaxName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a vaccine description')),
                      );
                      return;
                    }
                    setState(() {
                      final idx = _HealthcareData.patients.indexWhere((p) => p.id == patient.id);
                      if (idx != -1) {
                        final updatedList = List<String>.from(patient.vaccines)..add(vaxName);
                        _HealthcareData.patients[idx] = _Patient(
                          id: patient.id,
                          name: patient.name,
                          age: patient.age,
                          latestHeight: patient.latestHeight,
                          latestWeight: patient.latestWeight,
                          vaccines: updatedList,
                          lastCheckup: patient.lastCheckup,
                        );
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.vaccines_rounded, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Administered $vaxName successfully!')),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(12),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log Vaccine Inoculation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
    final list = _filteredPatients;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Pediatric Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search patients by name...',
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
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'No patients found.',
                        style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = list[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFE2894A).withValues(alpha: 0.12),
                                    child: Text(
                                      p.name[0],
                                      style: const TextStyle(color: Color(0xFFE2894A), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          'Patient ID: ${p.id} • ${p.age} years old',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Latest Height', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                      Text('${p.latestHeight} cm', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Latest Weight', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                      Text('${p.latestWeight} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Last Checkup', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                      Text(p.lastCheckup, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openGrowthSheet(p),
                                      icon: const Icon(Icons.show_chart_rounded, size: 16),
                                      label: const Text('Track Growth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFE2894A),
                                        side: const BorderSide(color: Color(0xFFE2894A)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openVaccineSheet(p),
                                      icon: const Icon(Icons.vaccines_rounded, size: 16),
                                      label: const Text('Vaccinations', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4A90E2),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
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

// ==================== CLINIC VISITS TAB ====================
class _HealthcareAppointmentsTab extends StatelessWidget {
  const _HealthcareAppointmentsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final appointments = [
      ('09:00 AM', 'Emma Watson', 'Annual Pediatric Checkup', 'Active', Colors.green),
      ('10:30 AM', 'Noah Centineo', 'Flu Vaccine Shot', 'Active', Colors.green),
      ('02:00 PM', 'Olivia Rodrigo', 'Vision & Hearing Test', 'Active', Colors.green),
      ('03:30 PM', 'Lucas Hedges', 'General Pediatric Consult', 'Active', Colors.green),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Upcoming Clinic Visits', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final visit = appointments[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2894A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.event_note_rounded, color: Color(0xFFE2894A), size: 24),
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
                            visit.$2,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: visit.$5.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              visit.$4,
                              style: TextStyle(color: visit.$5, fontWeight: FontWeight.bold, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visit.$3} • ${visit.$1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== PROFILE TAB ====================
class _HealthcareProfileTab extends StatelessWidget {
  const _HealthcareProfileTab();

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
            user?.fullName ?? 'Healthcare Provider',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? 'pediatrician@kidcare.com',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Center(
            child: Chip(
              label: Text(
                user?.role ?? 'Healthcare',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFFE2894A).withValues(alpha: 0.12),
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
                _ProfileStatRow(label: 'Assigned Clinic', value: 'Metro Pediatrics Clinic'),
                Divider(),
                _ProfileStatRow(label: 'License Registry', value: 'MD-9283-49A'),
                Divider(),
                _ProfileStatRow(label: 'Room Registry', value: 'Clinic Room 402'),
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
