import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/local_profile.dart';
import '../localization/app_strings.dart';
import '../state/profile_controller.dart';
import 'profile_avatar.dart';

class ProfileEditor extends ConsumerStatefulWidget {
  const ProfileEditor({
    super.key,
    required this.initial,
    required this.onClose,
  });
  final LocalProfile initial;
  final VoidCallback onClose;
  @override
  ConsumerState<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<ProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _email = TextEditingController(text: widget.initial.email);
  late Uint8List? _avatar = widget.initial.avatar;
  bool _saving = false;
  bool _picking = false;
  bool get _busy => _saving || _picking;
  String? _error;
  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final bytes = await ref.read(avatarPickerProvider)();
      if (bytes != null && mounted) setState(() => _avatar = bytes);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Не удалось выбрать фото. Попробуй ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(profileProvider.notifier)
          .save(
            LocalProfile(
              name: _name.text.trim(),
              email: _email.text.trim(),
              avatar: _avatar,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Профиль сохранён'.tr(context))));
        widget.onClose();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить. Попробуй ещё раз.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Личные данные'.tr(context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Center(
              child: ProfileAvatar(name: _name.text, bytes: _avatar),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey('choose-avatar'),
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text('Выбрать фото'.tr(context)),
                ),
                if (_avatar != null)
                  TextButton(
                    key: const ValueKey('remove-avatar'),
                    onPressed: _busy
                        ? null
                        : () => setState(() => _avatar = null),
                    child: Text('Убрать фото'.tr(context)),
                  ),
              ],
            ),
            Text(
              'JPG, PNG или WebP · до 5 МБ'.tr(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('profile-name'),
              controller: _name,
              readOnly: _busy,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Имя'.tr(context),
                hintText: 'Как тебя называть?'.tr(context),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('profile-email'),
              controller: _email,
              readOnly: _busy,
              maxLength: 254,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (value) =>
                  value == null ||
                      value.trim().isEmpty ||
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value.trim())
                  ? null
                  : 'Проверь формат email'.tr(context),
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Необязательно'.tr(context),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Это локальный профиль. Вход в аккаунт пока не подключён.'.tr(
                context,
              ),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!.tr(context), style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              children: [
                TextButton(
                  key: const ValueKey('cancel-profile'),
                  onPressed: _busy ? null : widget.onClose,
                  child: Text('Отмена'.tr(context)),
                ),
                FilledButton.icon(
                  key: const ValueKey('save-profile'),
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    (_saving ? 'Сохраняем…' : 'Сохранить').tr(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
