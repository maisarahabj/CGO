import 'package:flutter/material.dart';

import '../../../shared/widgets/temporary_linked_screen.dart';
import '../models/profile_model.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({required this.profile, super.key});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return const TemporaryLinkedScreen(
      title: 'Edit Information',
      pageName: 'Edit Information',
    );
  }
}
