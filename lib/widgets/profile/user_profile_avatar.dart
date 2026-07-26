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

  Future<void> _pickFrom(ImageSource source, UserModel user) async {
    if (!widget.editable) return;
    final auth = context.read<AuthProvider>();
    if (auth.profilePhotoUploading) return;

    try {
      final selected = await _picker.pickImage(
        source: source,
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 65,
      );
      if (selected == null || !mounted) return;

      final bytes = await selected.readAsBytes();
      if (!mounted) return;

      final success = await auth.updateProfilePhoto(imageBytes: bytes);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.softGreen,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        final err = auth.errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err != null && err.contains('unauthorized')
                  ? 'Upload blocked. Check Firebase Storage rules.'
                  : (err ?? 'Could not upload photo.'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showPickOptions(UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFrom(ImageSource.gallery, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFrom(ImageSource.camera, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel? user, Color accent, Uint8List? previewBytes) {
    if (previewBytes != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: MemoryImage(previewBytes),
      );
    }

    if (user?.hasProfilePhoto == true) {
      return CircleAvatar(
        key: ValueKey('photo-${user!.profilePic}'),
        radius: widget.radius,
        backgroundColor: accent.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(user.profilePic!),
        onBackgroundImageError: (_, __) {},
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
    final auth = context.watch<AuthProvider>();
    final authUser = widget.user ?? auth.currentUser;
    final previewBytes = auth.profilePhotoPreview;
    final uploading = auth.profilePhotoUploading;
    final accent = _accentFor(authUser);
    final gradient = _gradientFor(authUser);

    Widget avatar = _buildAvatar(authUser, accent, previewBytes);

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

    if (!widget.editable || authUser == null) {
      if (!uploading) return avatar;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: uploading ? null : () => _showPickOptions(authUser),
            customBorder: const CircleBorder(),
            child: avatar,
          ),
        ),
        if (uploading)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black26,
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
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: uploading ? null : () => _showPickOptions(authUser),
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
