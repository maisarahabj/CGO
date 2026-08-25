import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import 'profile_screen.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({required this.profile, super.key});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(profile: profile);
  }
}
