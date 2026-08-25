import 'package:flutter/material.dart';

import '../models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.profile,
    required this.onCameraPressed,
    this.isUploading = false,
    super.key,
  });

  final ProfileModel profile;
  final VoidCallback onCameraPressed;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.profileImageUrl;

    return SizedBox(
      width: 150,
      height: 138,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 110,
            height: 110,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A77B4), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _InitialsAvatar(initials: profile.initials);
                    },
                  )
                : _InitialsAvatar(initials: profile.initials),
          ),
          Positioned(
            right: 12,
            top: 78,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isUploading ? null : onCameraPressed,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD6D6D6)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: isUploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2A77B4),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          size: 19,
                          color: Color(0xFF2A77B4),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 102,
            child: Container(
              constraints: const BoxConstraints(minWidth: 81),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.role.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w800,
            fontSize: 34,
            color: Color(0xFF1E285F),
          ),
        ),
      ),
    );
  }
}
