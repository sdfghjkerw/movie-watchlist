import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/firebase_providers.dart';
import '../localization/app_strings.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.redirectPath});

  final String? redirectPath;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _creatingAccount = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_creatingAccount) {
        await repository.createAccount(
          email: _email.text,
          password: _password.text,
        );
      } else {
        await repository.signIn(email: _email.text, password: _password.text);
      }
      if (mounted) context.go(widget.redirectPath ?? '/account');
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error.code));
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось выполнить вход.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.signInWithGoogle();
      if (mounted) context.go(widget.redirectPath ?? '/account');
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error.code));
    } catch (_) {
      if (mounted) setState(() => _error = 'Вход через Google не завершён.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(String code) => switch (code) {
    'email-already-in-use' => 'Для этого email уже создан аккаунт.',
    'invalid-email' => 'Проверь формат email.',
    'weak-password' => 'Пароль должен содержать не менее 6 символов.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email или пароль не подошли.',
    'operation-not-allowed' =>
      'Включи этот способ входа в настройках Firebase Authentication.',
    'unauthorized-domain' =>
      'Firebase Auth не разрешает домен этой страницы. Открой локальную версию по адресу http://localhost:8765 вместо 127.0.0.1. Для другого адреса добавь домен в Authentication → Settings → Authorized domains.',
    'popup-blocked' =>
      'Браузер заблокировал окно Google. Разреши всплывающие окна и повтори попытку.',
    'popup-closed-by-user' || 'cancelled-popup-request' =>
      'Вход через Google отменён до завершения.',
    'network-request-failed' => 'Проверь подключение к интернету.',
    _ => 'Firebase не смог выполнить запрос ($code).',
  };

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(authRepositoryProvider);
    final configurationMessage = ref.watch(firebaseSetupMessageProvider);
    final colors = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Аккаунт Movie Watchlist'.tr(context))),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 760
                ? (constraints.maxWidth - 520) / 2
                : 24,
            vertical: 28,
          ),
          children: [
            Icon(Icons.movie_filter_rounded, size: 42, color: colors.secondary),
            const SizedBox(height: 20),
            Text(
              'Твой дневник, на всех устройствах'.tr(context),
              textAlign: TextAlign.center,
              style: type.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Войди или создай аккаунт, чтобы синхронизировать оценки, отзывы и коллекцию.'
                  .tr(context),
              textAlign: TextAlign.center,
              style: type.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            if (repository == null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      color: colors.secondary,
                      size: 30,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (configurationMessage ??
                              'Firebase пока не настроен для этого устройства.')
                          .tr(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Локальный дневник продолжает работать. Для входа заполни локальную конфигурацию; инструкции находятся в README.'
                          .tr(context),
                      textAlign: TextAlign.center,
                      style: type.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('auth-email'),
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email'.tr(context),
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Введи корректный email.'.tr(context)
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const ValueKey('auth-password'),
                      controller: _password,
                      enabled: !_busy,
                      obscureText: true,
                      autofillHints: [
                        _creatingAccount
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Пароль'.tr(context),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Пароль должен содержать не менее 6 символов.'.tr(
                              context,
                            )
                          : null,
                    ),
                    if (_creatingAccount) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey('auth-confirm-password'),
                        controller: _confirmation,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Повтори пароль'.tr(context),
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (value) => value != _password.text
                            ? 'Пароли не совпадают.'.tr(context)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!.tr(context),
                    key: const ValueKey('auth-error'),
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('auth-submit'),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        (_creatingAccount ? 'Создать аккаунт' : 'Войти').tr(
                          context,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('auth-google'),
                onPressed: _busy ? null : _googleSignIn,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: Text('Продолжить с Google'.tr(context)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _creatingAccount = !_creatingAccount;
                        _error = null;
                      }),
                child: Text(
                  (_creatingAccount
                          ? 'Уже есть аккаунт? Войти'
                          : 'Создать аккаунт')
                      .tr(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
