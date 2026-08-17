import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.profile, super.key});

  final ProfileModel profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _profileController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditing = false;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  DateTime? _draftDob;
  String? _dobError;

  @override
  void initState() {
    super.initState();

    _profileController = ProfileController(initialProfile: widget.profile);

    unawaited(_profileController.loadCurrentProfile());
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _profileController.dispose();

    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _draftDob = _profileController.profile?.dob ?? widget.profile.dob;
      _dobError = null;
    });
  }

  void _cancelEditing() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _isEditing = false;
      _draftDob = null;
      _dobError = null;
    });
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _draftDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _draftDob = selectedDate;
      _dobError = null;
    });
  }

  Future<void> _saveChanges() async {
    if (_draftDob == null) {
      setState(() {
        _dobError = 'Please select your date of birth.';
      });
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();

    final newPassword = _newPasswordController.text;

    final confirmPassword = _confirmPasswordController.text;

    final wantsPasswordChange =
        currentPassword.isNotEmpty ||
        newPassword.isNotEmpty ||
        confirmPassword.isNotEmpty;

    if (wantsPasswordChange) {
      if (currentPassword.isEmpty) {
        _showMessage('Please enter your current password.', isError: true);
        return;
      }

      if (newPassword.isEmpty) {
        _showMessage('Please enter a new password.', isError: true);
        return;
      }

      if (newPassword.length < 8) {
        _showMessage(
          'New password must contain at least 8 characters.',
          isError: true,
        );
        return;
      }

      if (newPassword != confirmPassword) {
        _showMessage(
          'New password and confirmation do not match.',
          isError: true,
        );
        return;
      }

      if (newPassword == currentPassword) {
        _showMessage(
          'New password must be different from your current password.',
          isError: true,
        );
        return;
      }
    }

    FocusScope.of(context).unfocus();

    final didSave = await _profileController.saveChanges(
      dob: _draftDob!,
      currentPassword: wantsPasswordChange ? currentPassword : null,
      newPassword: wantsPasswordChange ? newPassword : null,
    );

    if (!mounted) {
      return;
    }

    if (!didSave) {
      _showMessage(
        _profileController.errorMessage ??
            'Profile changes could not be saved.',
        isError: true,
      );
      return;
    }

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _isEditing = false;
      _draftDob = null;
      _dobError = null;
    });

    _showMessage(
      wantsPasswordChange
          ? 'Profile and password updated successfully.'
          : 'Profile updated successfully.',
      isError: false,
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : const Color(0xFF276749),
        ),
      );
  }

  String _formatDob(DateTime? dob) {
    if (dob == null) {
      return '-';
    }

    final day = dob.day.toString().padLeft(2, '0');

    final month = dob.month.toString().padLeft(2, '0');

    return '$day - $month - ${dob.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _profileController,
      builder: (context, _) {
        final profile = _profileController.profile ?? widget.profile;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          AppAssets.loginBackground,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(color: Color(0xFFEAF6F8));
                          },
                        ),
                      ),

                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 20, bottom: 36),
                        child: Column(
                          children: [
                            ProfileHeader(profile: profile),

                            const SizedBox(height: 6),

                            _buildInformationCard(profile),
                          ],
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
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            splashRadius: 22,
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            icon: SvgPicture.asset(AppAssets.hamburger, width: 27),
          ),

          const Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Campus',
                        style: TextStyle(color: Color(0xFF38358E)),
                      ),
                      TextSpan(
                        text: 'GO',
                        style: TextStyle(color: Color(0xFFFF0000)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          IconButton(
            tooltip: 'Close',
            splashRadius: 22,
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            icon: SvgPicture.asset(AppAssets.closeButton, width: 23),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(ProfileModel profile) {
    final displayedDob = _isEditing ? _draftDob : profile.dob;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        40,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    'Your Information',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xFF115388),
                    ),
                  ),
                ),

                Positioned(
                  right: 0,
                  child: IconButton(
                    tooltip: _isEditing ? 'Cancel editing' : 'Edit profile',
                    splashRadius: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _profileController.isLoading
                        ? null
                        : () {
                            if (_isEditing) {
                              _cancelEditing();
                            } else {
                              _startEditing();
                            }
                          },
                    icon: Icon(
                      _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                      size: 27,
                      color: const Color(0xFF126BA7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Full Name and Email are managed by UNIMY and cannot be edited here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF777777),
                ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          _readOnlyField(label: 'Full Name', value: profile.fullName ?? '-'),

          const SizedBox(height: 18),

          _readOnlyField(
            label: 'Email',
            value: _profileController.currentUserEmail ?? '-',
          ),

          const SizedBox(height: 18),

          if (_isEditing)
            _editableDobField(displayedDob)
          else
            _readOnlyField(label: 'DOB', value: _formatDob(displayedDob)),

          const SizedBox(height: 18),

          _readOnlyField(
            label: 'Password',
            value: '••••••••••••',
            obscure: true,
          ),

          if (_isEditing) ...[
            const SizedBox(height: 28),

            const Divider(color: Color(0xFFE1E1E1)),

            const SizedBox(height: 18),

            const Text(
              'Change Password',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF38358E),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Leave these fields empty if you only want to update your date of birth.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 20),

            _passwordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              obscure: _obscureCurrentPassword,
              onToggle: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),

            const SizedBox(height: 18),

            _passwordField(
              controller: _newPasswordController,
              label: 'New Password',
              obscure: _obscureNewPassword,
              onToggle: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),

            const SizedBox(height: 18),

            _passwordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              obscure: _obscureConfirmPassword,
              onToggle: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3235BD),
                      Color(0xFF7D2C87),
                      Color(0xFFFF2A0A),
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _profileController.isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: _profileController.isLoading
                      ? const SizedBox.square(
                          dimension: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: TextButton(
                onPressed: _profileController.isLoading ? null : _cancelEditing,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A057E),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF919191),
            ),
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          key: ValueKey('$label-$value'),
          initialValue: value,
          enabled: false,
          obscureText: obscure,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 17,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(
                color: Color(0xFF2A77B4),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editableDobField(DateTime? dob) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 18),
          child: Text(
            'DOB',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF919191),
            ),
          ),
        ),

        const SizedBox(height: 7),

        InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: _pickDob,
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: _dobError,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.only(
                left: 22,
                right: 10,
                top: 14,
                bottom: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: const BorderSide(color: Color(0xFF2A77B4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: const BorderSide(
                  color: Color(0xFF2A77B4),
                  width: 1.2,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dob != null)
                    IconButton(
                      tooltip: 'Clear DOB',
                      onPressed: () {
                        setState(() {
                          _draftDob = null;
                          _dobError = null;
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF6B6B6B)),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            child: Text(
              dob == null ? 'Select date' : _formatDob(dob),
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: dob == null
                    ? const Color(0xFF919191)
                    : const Color(0xFF424242),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF919191),
            ),
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            color: Color(0xFF424242),
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 17,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF777777),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(
                color: Color(0xFF2A77B4),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: Color(0xFF2A77B4), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
