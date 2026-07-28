import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../home/views/guest_home_screen.dart';
import '../controllers/auth_controller.dart';
import '../widgets/guest_access_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authController,
    super.key,
  });

  final AuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final didSignIn = await widget.authController.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || didSignIn) {
      return;
    }

    _showMessage(
      widget.authController.errorMessage ??
          'The email or password is incorrect.',
      isError: true,
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final resetFormKey = GlobalKey<FormState>();

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: Form(
            key: resetFormKey,
            child: TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@example.com',
              ),
              validator: _validateEmail,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (resetFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Send email'),
            ),
          ],
        );
      },
    );

    if (shouldSend != true || !mounted) {
      resetEmailController.dispose();
      return;
    }

    final email = resetEmailController.text;
    resetEmailController.dispose();

    final didSend =
        await widget.authController.sendPasswordResetEmail(email);

    if (!mounted) {
      return;
    }

    _showMessage(
      didSend
          ? 'Password-reset instructions were sent to your email.'
          : widget.authController.errorMessage ??
              'The password-reset email could not be sent.',
      isError: !didSend,
    );
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const GuestHomeScreen(),
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFB3261E) : const Color(0xFF276749),
        ),
      );
  }

  static String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email.';
    }

    final looksLikeEmail =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!looksLikeEmail) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AnimatedBuilder(
          animation: widget.authController,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final keyboardIsOpen =
                    MediaQuery.viewInsetsOf(context).bottom > 0;
                final canvasHeight = constraints.maxHeight < 720
                    ? 780.0
                    : constraints.maxHeight;
                final panelHeight =
                    (canvasHeight * 0.55).clamp(500.0, 560.0).toDouble();

                return SingleChildScrollView(
                  reverse: keyboardIsOpen,
                  child: SizedBox(
                    height: canvasHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _LoginBackground(
                          assetPath: AppAssets.loginBackground,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x170B2942),
                              ],
                              stops: [0.56, 1],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Container(
                              height: panelHeight,
                              padding: const EdgeInsets.fromLTRB(
                                34,
                                22,
                                34,
                                18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FCFF)
                                    .withValues(alpha: 0.92),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(48),
                                ),
                              ),
                              child: SafeArea(
                                top: false,
                                child: SingleChildScrollView(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _CampusGoBrand(),
                                        const SizedBox(height: 16),
                                        _LoginTextField(
                                          controller: _emailController,
                                          hintText: 'Email',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.username,
                                            AutofillHints.email,
                                          ],
                                          validator: _validateEmail,
                                          textInputAction:
                                              TextInputAction.next,
                                        ),
                                        const SizedBox(height: 16),
                                        _LoginTextField(
                                          controller: _passwordController,
                                          hintText: 'Password',
                                          obscureText: _obscurePassword,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          validator: _validatePassword,
                                          textInputAction:
                                              TextInputAction.done,
                                          onFieldSubmitted: (_) => _signIn(),
                                          suffixIcon: IconButton(
                                            tooltip: _obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color:
                                                  const Color(0xFF6C6C73),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 44,
                                          child: TextButton(
                                            onPressed:
                                                widget.authController.isLoading
                                                    ? null
                                                    : _showForgotPasswordDialog,
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFF4A057E),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            child:
                                                const Text('Forgot password?'),
                                          ),
                                        ),
                                        _GradientSignInButton(
                                          isLoading:
                                              widget.authController.isLoading,
                                          onPressed: _signIn,
                                        ),
                                        const SizedBox(height: 14),
                                        GuestAccessButton(
                                          isEnabled:
                                              !widget.authController.isLoading,
                                          onPressed: _continueAsGuest,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) {
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFBCECF1),
                Color(0xFF8ED9E5),
                Color(0xFFE7F8F8),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 300),
              child: Text(
                'Add login_background.png',
                style: TextStyle(
                  color: Color(0xFF24586A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CampusGoBrand extends StatelessWidget {
  const _CampusGoBrand();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.campusGoLocationPin,
            width: 62,
            height: 82,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 62,
                child: Icon(
                  Icons.location_on,
                  size: 74,
                  color: Color(0xFFE20818),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 43,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Campus',
                          style: TextStyle(
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Color(0xFF3536C4),
                                  Color(0xFF65288E),
                                ],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 190, 50),
                              ),
                          ),
                        ),
                        const TextSpan(
                          text: 'GO',
                          style: TextStyle(color: Color(0xFFFF1010)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: Color(0xFF4A176B),
                        fontSize: 19,
                        height: 1,
                        fontStyle: FontStyle.italic,
                      ),
                      children: [
                        TextSpan(text: 'A '),
                        TextSpan(
                          text: 'UNIMY',
                          style: TextStyle(
                            color: Color(0xFFE31B23),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: ' Navigation App'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF25252B),
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFB8B8BD),
          fontSize: 19,
        ),
        errorMaxLines: 2,
        filled: true,
        fillColor: const Color(0xFFFDFDFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 17,
        ),
        suffixIcon: suffixIcon,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          borderSide: BorderSide(
            color: Color(0xFF0077C8),
            width: 1.4,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          borderSide: BorderSide(
            color: Color(0xFF4A057E),
            width: 2,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          borderSide: BorderSide(
            color: Color(0xFFB3261E),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          borderSide: BorderSide(
            color: Color(0xFFB3261E),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _GradientSignInButton extends StatelessWidget {
  const _GradientSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3235BD),
            Color(0xFF7D2C87),
            Color(0xFFFF2A0A),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: isLoading
              ? const SizedBox.square(
                  dimension: 25,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.6,
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
