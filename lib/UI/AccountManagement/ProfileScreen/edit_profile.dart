import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/base_providers.dart';
import 'package:stripes_ui/Models/profile_condition.dart';
import 'package:stripes_ui/Providers/profile_condition_provider.dart';
import 'package:stripes_ui/Providers/shared_service_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/profile_condition_field.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/AccountManagement/birth_year_selector.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/Util/Helpers/form_input.dart';
import 'package:stripes_ui/config.dart';

import 'profile_avatar.dart';

/// Content for the adaptive sheet supplied by the sheet controller.
class EditUserWidget extends ConsumerStatefulWidget {
  final SubUser subUser;

  const EditUserWidget({required this.subUser, super.key});

  @override
  ConsumerState<EditUserWidget> createState() => _EditUserWidgetState();
}

class _EditUserWidgetState extends ConsumerState<EditUserWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final TextEditingController _firstName, _lastName;
  late final BirthYearController _birthYearController;
  late final bool _isName;
  bool _conditionLoaded = false;
  ProfileCondition? _condition, _originalCondition;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isName = ref.read(configProvider).profileType == ProfileType.name;
    final names = widget.subUser.name.trim().split(RegExp(r'\s+'));
    _firstName = TextEditingController(
      text: _isName ? names.first : widget.subUser.name,
    );
    _lastName = TextEditingController(
      text: _isName ? names.skip(1).join(' ') : '',
    );
    _birthYearController = BirthYearController(
      initialYear: widget.subUser.birthYear,
    );
    _firstName.addListener(_changed);
    _lastName.addListener(_changed);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _error = null);

  String get _name => _isName
      ? [
          _firstName.text.trim(),
          _lastName.text.trim(),
        ].where((part) => part.isNotEmpty).join(' ')
      : _firstName.text.trim();

  SubUser get _draft => SubUser(
    id: widget.subUser.uid,
    name: _name,
    birthYear: _isName ? _birthYearController.year : widget.subUser.birthYear,
    gender: widget.subUser.gender,
    isControl: widget.subUser.isControl,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_isName) {
      final stored = ref.watch(profileConditionProvider(widget.subUser.uid));
      if (!_conditionLoaded) {
        if (!stored.hasValue) {
          return Padding(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Profile'),
                const SizedBox(height: AppPadding.large),
                if (stored.hasError) ...[
                  const Text('Unable to load the saved condition.'),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      profileConditionProvider(widget.subUser.uid),
                    ),
                    child: const Text('Try again'),
                  ),
                ] else
                  const CircularProgressIndicator(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }
        _condition = _originalCondition = stored.value;
        _conditionLoaded = true;
      }
    }
    final canSave =
        !_isSaving &&
        (!subEquals(_draft, widget.subUser) ||
            _condition != _originalCondition);
    final cancel = TextButton(
      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    );
    final save = FilledButton(
      onPressed: canSave ? _save : null,
      child: Text(_isSaving ? 'Saving…' : 'Save'),
    );
    final title = Text(
      'Edit Profile',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.xl),
        child: Form(
          key: _formKey,
          onChanged: _changed,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 350 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  return stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            title,
                            const SizedBox(height: AppPadding.small),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: AppPadding.small,
                              runSpacing: AppPadding.small,
                              children: [cancel, save],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            cancel,
                            Expanded(child: title),
                            save,
                          ],
                        );
                },
              ),
              const Divider(height: AppPadding.xxl),
              Center(child: ProfileAvatar(name: _name, radius: 36)),
              const SizedBox(height: AppPadding.xl),
              TextFormField(
                key: const ValueKey('profile-first-name'),
                controller: _firstName,
                enabled: !_isSaving,
                textCapitalization: _isName
                    ? TextCapitalization.words
                    : TextCapitalization.none,
                textInputAction: _isName
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: _requiredName,
                onFieldSubmitted: _isName ? null : (_) => _save(),
                decoration: formFieldDecoration(
                  hintText: _isName ? 'First name' : 'Username',
                  controller: _firstName,
                  clearable: false,
                ),
              ),
              if (_isName) ...[
                const SizedBox(height: AppPadding.large),
                TextFormField(
                  key: const ValueKey('profile-last-name'),
                  controller: _lastName,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  // Existing one-word profiles remain editable.
                  validator: widget.subUser.name.trim().contains(RegExp(r'\s'))
                      ? _requiredName
                      : null,
                  decoration: formFieldDecoration(
                    hintText: 'Last name',
                    controller: _lastName,
                    clearable: false,
                  ),
                ),
                const SizedBox(height: AppPadding.large),
                IgnorePointer(
                  ignoring: _isSaving,
                  child: BirthYearSelector(
                    context: context,
                    controller: _birthYearController,
                  ),
                ),
                const SizedBox(height: AppPadding.large),
                ProfileConditionField(
                  initialValue: _condition,
                  enabled: !_isSaving,
                  onChanged: (value) => setState(() {
                    _condition = value;
                    _error = null;
                  }),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppPadding.large),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: TextStyle(color: colors.error)),
                ),
              ],
              const SizedBox(height: AppPadding.xxl),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete this profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredName(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter a name' : null;

  Future<void> _save() async {
    if (_isSaving ||
        (subEquals(_draft, widget.subUser) &&
            _condition == _originalCondition)) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = _draft;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final repo = await ref.read(subProvider.future);
      if (repo == null) {
        if (mounted) {
          setState(
            () => _error = 'Unable to save this profile. Please try again.',
          );
        }
        return;
      }
      if (!subEquals(updated, widget.subUser)) {
        final result = await repo.updateSubUser(updated);
        if (!mounted) return;
        if (result case Failure(:final message)) {
          setState(() => _error = message);
          return;
        }
      }
      if (_isName && _condition != _originalCondition) {
        await ref
            .read(profileConditionProvider(widget.subUser.uid).notifier)
            .save(_condition);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to save this profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmation(toDelete: widget.subUser),
    );
    if (deleted == true && mounted) Navigator.of(context).pop();
  }
}

class DeleteConfirmation extends ConsumerStatefulWidget {
  final SubUser toDelete;

  const DeleteConfirmation({required this.toDelete, super.key});

  @override
  ConsumerState<DeleteConfirmation> createState() => _DeleteConfirmationState();
}

class _DeleteConfirmationState extends ConsumerState<DeleteConfirmation> {
  bool _isDeleting = false;
  bool _profileDeleted = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      icon: Icon(Icons.warning_amber_rounded, color: colors.error),
      title: const Text('Delete this profile?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All logged data for ${widget.toDelete.name} will be permanently removed. This cannot be undone.',
          ),
          if (_error != null) ...[
            const SizedBox(height: AppPadding.medium),
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: TextStyle(color: colors.error)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: _isDeleting ? null : _confirm,
          child: Text(_isDeleting ? 'Deleting…' : 'Delete'),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      final repo = await ref.read(subProvider.future);
      if (repo == null) {
        if (mounted) {
          setState(
            () => _error = 'Unable to delete this profile. Please try again.',
          );
        }
        return;
      }
      final service = ref.read(sharedSeviceProvider);
      if (!_profileDeleted) {
        final result = await repo.deleteSubUser(widget.toDelete);
        if (result case Failure(:final message)) {
          if (mounted) setState(() => _error = message);
          return;
        }
        _profileDeleted = true;
      }
      // Complete local cleanup even if the dialog closes during deletion.
      await service.setProfileCondition(
        accountId: repo.authUser.uid,
        profileId: widget.toDelete.uid,
        condition: null,
      );
      if (mounted) {
        ref.invalidate(profileConditionProvider(widget.toDelete.uid));
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to delete this profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}

bool subEquals(SubUser user1, SubUser user2) =>
    user1.uid == user2.uid &&
    user1.birthYear == user2.birthYear &&
    user1.gender == user2.gender &&
    user1.name == user2.name &&
    user1.isControl == user2.isControl;
