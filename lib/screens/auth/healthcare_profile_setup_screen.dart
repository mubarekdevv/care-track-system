import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/school_config.dart';
import '../../core/health/health_concerns.dart';
import '../../core/theme/app_theme.dart';
import '../../models/staff_profile_models.dart';
import '../../data/firestore/firestore_doctor_matching_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/auth/auth_primary_button.dart';

/// Healthcare setup: pick specialties from the school's enabled health services.
class HealthcareProfileSetupScreen extends StatefulWidget {
  const HealthcareProfileSetupScreen({super.key, this.isFirstLogin = false});

  /// Shown right after sign-in when registration did not include health services.
  final bool isFirstLogin;

  @override
  State<HealthcareProfileSetupScreen> createState() =>
      _HealthcareProfileSetupScreenState();
}

class _HealthcareProfileSetupScreenState
    extends State<HealthcareProfileSetupScreen> {
  final _clinicController = TextEditingController();
  final _licenseController = TextEditingController();
  final _roomController = TextEditingController();
  final Set<String> _selectedSpecialtyIds = {};
  bool _saving = false;
  bool _deferring = false;
  bool _loadedExisting = false;

  @override
  void dispose() {
    _clinicController.dispose();
    _licenseController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _loadExistingProfile(AuthProvider auth) {
    if (_loadedExisting) return;
    final profile = auth.currentUser?.healthcareProfile;
    if (profile == null) return;
    _loadedExisting = true;
    _clinicController.text = profile.clinicName ?? '';
    _licenseController.text = profile.licenseId ?? '';
    _roomController.text = profile.room ?? '';
    _selectedSpecialtyIds
      ..clear()
      ..addAll(profile.specialtyIds);
  }

  Future<void> _save(SchoolAdminProvider school) async {
    if (_selectedSpecialtyIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one health service you can provide.'),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final enabled = school.enabledHealthSpecialtyIds;
    final allowed = _selectedSpecialtyIds.where((id) {
      if (enabled.isEmpty) return true;
      return enabled.contains(id);
    }).toList();
    if (allowed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick services from your school\'s enabled list.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = HealthcareProfile(
        clinicName: _clinicController.text.trim().isEmpty
            ? null
            : _clinicController.text.trim(),
        licenseId: _licenseController.text.trim().isEmpty
            ? null
            : _licenseController.text.trim(),
        room: _roomController.text.trim().isEmpty
            ? null
            : _roomController.text.trim(),
        specialtyIds: allowed..sort(),
      );
      final schoolId = user.schoolId ?? SchoolConfig.defaultSchoolId;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'schoolId': schoolId,
        'healthcareProfile': profile.toMap(),
        'healthcareSetupComplete': true,
        'healthcareProfileSetupDeferred': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirestoreDoctorMatchingRepository().updateHealthcareSpecialties(
        doctorUserId: user.uid,
        specialtyIds: allowed,
        schoolId: schoolId,
      );
      await auth.refreshUserProfile();
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completeLater() async {
    setState(() => _deferring = true);
    final ok = await context.read<AuthProvider>().deferHealthcareProfileSetup();
    if (!mounted) return;
    setState(() => _deferring = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not continue. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final school = context.watch<SchoolAdminProvider>();
    final auth = context.watch<AuthProvider>();
    _loadExistingProfile(auth);
    final isEditing = auth.isHealthcareProfileComplete;
    final showFirstLogin = widget.isFirstLogin && !isEditing;

    final options = HealthConcerns.clinicalForSchool(school.enabledHealthSpecialtyIds);
    if (options.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            showFirstLogin ? 'Set up your clinic profile' : 'Healthcare profile',
          ),
          automaticallyImplyLeading: isEditing,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showFirstLogin) ...[
                Text(
                  'Welcome, ${auth.currentUser?.fullName ?? 'Doctor'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Your school admin has not enabled health services yet. '
                'Ask them to configure services on the admin Home tab, then return here '
                'from your Profile tab to select the care you provide.',
                style: TextStyle(height: 1.45),
              ),
              if (showFirstLogin) ...[
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: _deferring ? null : _completeLater,
                    child: Text(
                      _deferring ? 'Opening dashboard…' : 'Open dashboard for now',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Update healthcare profile'
              : showFirstLogin
                  ? 'Set up your clinic profile'
                  : 'Healthcare profile',
        ),
        automaticallyImplyLeading: isEditing,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showFirstLogin) ...[
                Text(
                  'Welcome, ${auth.currentUser?.fullName ?? 'Healthcare professional'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account was created without health services listed. '
                  'Choose the care you provide so parents and enrolled students can be linked to you.',
                  style: TextStyle(
                    height: 1.45,
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2894A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Select the health areas you can assist with at this school. '
                  'Parents who enroll children with matching needs can be assigned to you. '
                  'The admin may also link your account from the Staff tab.',
                  style: TextStyle(height: 1.45, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _clinicController,
                decoration: InputDecoration(
                  labelText: 'Clinic name (optional)',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _licenseController,
                decoration: InputDecoration(
                  labelText: 'License / ID (optional)',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room (optional)',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Health services you provide',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((concern) {
                  final selected = _selectedSpecialtyIds.contains(concern.id);
                  return FilterChip(
                    avatar: Icon(concern.icon, size: 18),
                    label: Text(concern.label),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedSpecialtyIds.add(concern.id);
                        } else {
                          _selectedSpecialtyIds.remove(concern.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(
                label: _saving
                    ? 'Saving…'
                    : isEditing
                        ? 'Save profile'
                        : 'Save and open dashboard',
                onPressed: _saving ? null : () => _save(school),
              ),
              if (showFirstLogin) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: (_saving || _deferring) ? null : _completeLater,
                    child: Text(
                      _deferring ? 'Opening dashboard…' : 'Complete later',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
