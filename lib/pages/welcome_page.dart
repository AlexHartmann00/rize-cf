
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/helpers/auth_service.dart';
import 'package:rize/pages/home_page.dart';
import 'package:rize/widgets/welcome_widgets.dart';

enum WelcomeView {
  intro,
  authChoice,
  login,
  register,
  passwordReset,
  passwordResetSuccess,
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final GlobalKey<FormState> _authFormKey =
      GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordResetFormKey =
      GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _displayNameController =
      TextEditingController();

  WelcomeView _view = WelcomeView.intro;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: null,
      bottomNavigationBar: null,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: AutofillGroup(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: <Widget>[
                      const WelcomeBrandHero(),
                      const SizedBox(height: 28),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.035),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildCurrentView(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_view) {
      case WelcomeView.intro:
        return WelcomeIntroCard(
          key: const ValueKey<String>('intro'),
          onContinue: () {
            setState(() => _view = WelcomeView.authChoice);
          },
        );

      case WelcomeView.authChoice:
        return AuthChoiceCard(
          key: const ValueKey<String>('choice'),
          onBack: () {
            setState(() => _view = WelcomeView.intro);
          },
          onLogin: () {
            setState(() => _view = WelcomeView.login);
          },
          onRegister: () {
            setState(() => _view = WelcomeView.register);
          },
        );

      case WelcomeView.login:
        return WelcomeAuthForm(
          key: const ValueKey<String>('login'),
          isLogin: true,
          formKey: _authFormKey,
          emailController: _emailController,
          passwordController: _passwordController,
          displayNameController: _displayNameController,
          obscurePassword: _obscurePassword,
          isLoading: _isLoading,
          onSubmit: _submitAuthentication,
          onBack: _returnToAuthChoice,
          onTogglePasswordVisibility:
              _togglePasswordVisibility,
          onForgotPassword: () {
            setState(
              () => _view = WelcomeView.passwordReset,
            );
          },
        );

      case WelcomeView.register:
        return WelcomeAuthForm(
          key: const ValueKey<String>('register'),
          isLogin: false,
          formKey: _authFormKey,
          emailController: _emailController,
          passwordController: _passwordController,
          displayNameController: _displayNameController,
          obscurePassword: _obscurePassword,
          isLoading: _isLoading,
          onSubmit: _submitAuthentication,
          onBack: _returnToAuthChoice,
          onTogglePasswordVisibility:
              _togglePasswordVisibility,
        );

      case WelcomeView.passwordReset:
        return PasswordResetCard(
          key: const ValueKey<String>('reset'),
          formKey: _passwordResetFormKey,
          emailController: _emailController,
          isLoading: _isLoading,
          onSubmit: _submitPasswordReset,
          onBack: () {
            setState(() => _view = WelcomeView.login);
          },
        );

      case WelcomeView.passwordResetSuccess:
        return PasswordResetSuccessCard(
          key: const ValueKey<String>('reset-success'),
          email: _emailController.text.trim(),
          onBackToLogin: () {
            setState(() => _view = WelcomeView.login);
          },
        );
    }
  }

  Future<void> _submitAuthentication() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_authFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final bool isLogin = _view == WelcomeView.login;
    final AuthResult result;

    if (isLogin) {
      result = await authServiceNotifier.value
          .signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      result = await authServiceNotifier.value
          .registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        _displayNameController.text,
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.success) {
      _showError(
        result.errorMessage ??
            'Der Vorgang konnte nicht abgeschlossen werden.',
      );
      return;
    }

    TextInput.finishAutofillContext();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const MyHomePage(title: 'RIZE'),
      ),
    );
  }

  Future<void> _submitPasswordReset() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_passwordResetFormKey.currentState?.validate() ??
        false)) {
      return;
    }

    setState(() => _isLoading = true);

    final PasswordResetResult result =
        await authServiceNotifier.value.sendPasswordResetEmail(
      _emailController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.success) {
      _showError(
        result.errorMessage ??
            'Der Reset-Link konnte nicht versendet werden.',
      );
      return;
    }

    setState(() {
      _view = WelcomeView.passwordResetSuccess;
    });
  }

  void _returnToAuthChoice() {
    if (_isLoading) return;

    setState(() {
      _view = WelcomeView.authChoice;
      _passwordController.clear();
      _obscurePassword = true;
    });
  }

  void _togglePasswordVisibility() {
    setState(
      () => _obscurePassword = !_obscurePassword,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }
}
