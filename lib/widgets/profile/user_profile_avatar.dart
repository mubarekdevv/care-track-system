import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/role_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

/// Role-aware profile avatar with optional photo upload via [AuthProvider].
class UserProfileAvatar extends StatefulWidget {
  final UserModel? user;
  final double radius;
  final bool editable;
  final bool showGradientRing;

  const UserProfileAvatar({
    super.key,
    this.user,
    this.radius = 44,
    this.editable = true,
    this.showGradientRing = true,
  });

  @override
  State<UserProfileAvatar> createState() => _UserProfileAvatarState();
}

class _UserProfileAvatarState extends State<UserProfileAvatar> {
  final _picker = ImagePicker();
  Uint8List? _localPreview;
  bool _uploading = false;

  Color _accentFor(UserModel? user) {
    final role = user?.role ?? 'Parent';
    return RoleStyles.forRole(role)['accent'] as Color;
  }

  LinearGradient _gradientFor(UserModel? user) {
    final role = user?.role ?? 'Parent';
    return RoleStyles.forRole(role)['gradient'] as LinearGradient;
  }

  String _initial(UserModel? user) {
    if (user?.fullName.isNotEmpty == true) {
      return user!.fullName[0].toUpperCase();
    }
    final role = user?.role ?? 'P';
    return role.isNotEmpty ? role[0].toUpperCase() : '?';
  }

  Future<void> _pickAndUpload(UserModel user) async {
    if (!widget.editable || _uploading) return;

    try {
      final selected = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (selected == null || !mounted) return;

      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _localPreview = bytes;
        _uploading = true;
      });

      final success = await Provider.of<AuthProvider>(context, listen: false)
          .updateProfilePhoto(imageBytes: bytes);

      if (!mounted) return;

      setState(() => _uploading = false);

      if (success) {
        setState(() => _localPreview = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.softGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not upload photo. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildAvatar(UserModel? user, Color accent) {
    if (_localPreview != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: MemoryImage(_localPreview!),
      );
    }

    if (user?.hasProfilePhoto == true) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: accent.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(user!.profilePic!),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: accent.withValues(alpha: 0.15),
      child: Text(
        _initial(user),
        style: TextStyle(
          fontSize: widget.radius * 0.75,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = widget.user ?? Provider.of<AuthProvider>(context).currentUser;
    final accent = _accentFor(authUser);
    final gradient = _gradientFor(authUser);

    Widget avatar = _buildAvatar(authUser, accent);

    if (widget.showGradientRing) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: avatar,
        ),
      );
    }

    if (!widget.editable || authUser == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pickAndUpload(authUser),
            customBorder: const CircleBorder(),
            child: avatar,
          ),
        ),
        if (_uploading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          ),
        if (widget.editable)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickAndUpload(authUser),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
