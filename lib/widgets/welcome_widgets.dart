
import 'package:flutter/material.dart';
import 'package:rize/helpers/rize_style_helpers.dart';

class WelcomeBrandHero extends StatelessWidget {
  const WelcomeBrandHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF79D5FF),
                Color(0xFF176BC7),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF176BC7).withOpacity(0.42),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'RIZE',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dein täglicher Impuls für einen stärkeren Körper.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.72),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            'EINE APP VON COACH FLO',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class WelcomeIntroCard extends StatelessWidget {
  const WelcomeIntroCard({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return WelcomeGlassPanel(
      child: Column(
        children: <Widget>[
          const WelcomeBenefit(
            icon: Icons.auto_awesome_rounded,
            title: 'Täglich neu',
            text: 'Dein Workout wird passend zu Deinem Level ausgewählt.',
          ),
          const SizedBox(height: 14),
          const WelcomeBenefit(
            icon: Icons.schedule_rounded,
            title: 'Einfach im Alltag',
            text: 'Kurze, klare Einheiten ohne komplizierte Planung.',
          ),
          const SizedBox(height: 14),
          const WelcomeBenefit(
            icon: Icons.show_chart_rounded,
            title: 'Fortschritt, der motiviert',
            text: 'Serien, Level und Impact machen Erfolge sichtbar.',
          ),
          const SizedBox(height: 22),
          WelcomePrimaryButton(
            label: 'JETZT LOSLEGEN',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class AuthChoiceCard extends StatelessWidget {
  const AuthChoiceCard({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onBack,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return WelcomeGlassPanel(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Wie möchtest Du starten?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          WelcomePrimaryButton(
            label: 'NEUES KONTO ERSTELLEN',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: onRegister,
          ),
          const SizedBox(height: 10),
          WelcomeSecondaryButton(
            label: 'ICH HABE BEREITS EIN KONTO',
            icon: Icons.login_rounded,
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}

class WelcomeAuthForm extends StatelessWidget {
  const WelcomeAuthForm({
    super.key,
    required this.isLogin,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.displayNameController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
    required this.onTogglePasswordVisibility,
    this.onForgotPassword,
  });

  final bool isLogin;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController displayNameController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return WelcomeGlassPanel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: isLoading ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isLogin
                            ? 'Willkommen zurück'
                            : 'Dein RIZE-Konto',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isLogin
                            ? 'Melde Dich an und setze Deine Serie fort.'
                            : 'Ein paar Angaben – dann kann es direkt losgehen.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.52),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!isLogin) ...<Widget>[
              WelcomeTextField(
                controller: displayNameController,
                label: 'Dein Name',
                hint: 'Wie dürfen wir Dich nennen?',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Bitte gib Deinen Namen ein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            WelcomeTextField(
              controller: emailController,
              label: 'E-Mail-Adresse',
              hint: 'name@beispiel.de',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
              validator: (String? value) {
                final String email = (value ?? '').trim();

                if (email.isEmpty) {
                  return 'Bitte gib Deine E-Mail-Adresse ein.';
                }

                if (!email.contains('@') || !email.contains('.')) {
                  return 'Bitte gib eine gültige E-Mail-Adresse ein.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            WelcomeTextField(
              controller: passwordController,
              label: 'Passwort',
              hint: isLogin ? 'Dein Passwort' : 'Mindestens 6 Zeichen',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: <String>[
                isLogin
                    ? AutofillHints.password
                    : AutofillHints.newPassword,
              ],
              suffixIcon: IconButton(
                onPressed:
                    isLoading ? null : onTogglePasswordVisibility,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              onSubmitted: (_) => onSubmit(),
              validator: (String? value) {
                final String password = value ?? '';

                if (password.isEmpty) {
                  return 'Bitte gib Dein Passwort ein.';
                }

                if (!isLogin && password.length < 6) {
                  return 'Das Passwort muss mindestens 6 Zeichen haben.';
                }

                return null;
              },
            ),
            if (isLogin && onForgotPassword != null) ...<Widget>[
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : onForgotPassword,
                  child: const Text(
                    'Passwort vergessen?',
                    style: TextStyle(
                      color: rizeCyan,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 18),
            WelcomePrimaryButton(
              label: isLogin ? 'EINLOGGEN' : 'KONTO ERSTELLEN',
              icon: isLogin
                  ? Icons.login_rounded
                  : Icons.person_add_alt_1_rounded,
              loading: isLoading,
              onPressed: isLoading ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetCard extends StatelessWidget {
  const PasswordResetCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return WelcomeGlassPanel(
      child: Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: isLoading ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Passwort zurücksetzen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Wir senden Dir einen sicheren Link, mit dem Du ein neues '
              'Passwort festlegen kannst.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            WelcomeTextField(
              controller: emailController,
              label: 'E-Mail-Adresse',
              hint: 'name@beispiel.de',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              validator: (String? value) {
                final String email = (value ?? '').trim();

                if (email.isEmpty || !email.contains('@')) {
                  return 'Bitte gib Deine E-Mail-Adresse ein.';
                }

                return null;
              },
            ),
            const SizedBox(height: 18),
            WelcomePrimaryButton(
              label: 'RESET-LINK SENDEN',
              icon: Icons.mark_email_read_outlined,
              loading: isLoading,
              onPressed: isLoading ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetSuccessCard extends StatelessWidget {
  const PasswordResetSuccessCard({
    super.key,
    required this.email,
    required this.onBackToLogin,
  });

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return WelcomeGlassPanel(
      child: Column(
        children: <Widget>[
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: rizeGreen.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: rizeGreen.withOpacity(0.30),
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: rizeGreen,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'E-Mail ist unterwegs',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wir haben den Link an $email gesendet. Prüfe bitte auch '
            'Deinen Spam-Ordner.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          WelcomePrimaryButton(
            label: 'ZURÜCK ZUM LOGIN',
            icon: Icons.login_rounded,
            onPressed: onBackToLogin,
          ),
        ],
      ),
    );
  }
}

class WelcomeTextField extends StatelessWidget {
  const WelcomeTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: !obscureText,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF19324F),
        fontWeight: FontWeight.w700,
      ),
      cursorColor: rizeBlue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F8FE),
        labelStyle: const TextStyle(
          color: Color(0xFF4D6581),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8495AA),
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: rizeBlue,
        suffixIconColor: const Color(0xFF4D6581),
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFFD8E3F4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: rizeBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class WelcomePrimaryButton extends StatelessWidget {
  const WelcomePrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Colors.white,
        foregroundColor: rizeBlue,
        disabledBackgroundColor: Colors.white.withOpacity(0.24),
        disabledForegroundColor: Colors.white.withOpacity(0.60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      icon: loading
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
              ),
            )
          : Icon(icon),
      label: Text(
        loading ? 'BITTE WARTEN …' : label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}

class WelcomeSecondaryButton extends StatelessWidget {
  const WelcomeSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withOpacity(0.18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class WelcomeBenefit extends StatelessWidget {
  const WelcomeBenefit({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: rizeCyan.withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: rizeCyan,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WelcomeGlassPanel extends StatelessWidget {
  const WelcomeGlassPanel({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.07),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.17),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
