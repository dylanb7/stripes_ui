import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/route_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = MediaQuery.of(context).size.width < 1400;
    const double itemWidth = SMALL_LAYOUT / 1.5;

    final subNotifier = ref.watch(subHolderProvider);
    if (subNotifier.isLoading) {
      return const LoadingWidget();
    }
    final List<SubUser> subUsers = subNotifier.valueOrNull?.subUsers ?? [];
    final SubUser? current = subNotifier.valueOrNull?.selected;
    return PageWrap(
      actions: [
        if (!isSmall)
          ...TabOption.values.map((tab) => LargeNavButton(tab: tab)),
        const UserProfileButton(
          selected: true,
        )
      ],
      bottomNav: isSmall ? const SmallLayout() : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          Row(children: [
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
              textAlign: TextAlign.left,
            ),
            const Spacer(),
            FilledButton(
                onPressed: () async {
                  await ref.read(authProvider).logOut();
                  ref.invalidate(routeProvider);
                },
                child: Text(AppLocalizations.of(context)!.logOutButton))
          ]),
          const Divider(),
          ListTile(
            dense: false,
            visualDensity: VisualDensity.comfortable,
            title: const Text("Profiles"),
            trailing: const Icon(Icons.keyboard_arrow_right),
            subtitle: current?.name != null
                ? Text(
                    current!.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : null,
            onTap: () {
              context.goNamed(Routes.USERS);
            },
          ),
          const Divider(),
          const SizedBox(
            height: 12.0,
          ),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(overlayProvider.notifier).state =
                    const CurrentOverlay(widget: DeleteAccountPopup());
              },
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.2))),
              child: Text(
                "Delete account",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteAccountPopup extends ConsumerStatefulWidget {
  const DeleteAccountPopup({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _DeleteAccountPopupState();
  }
}

class _DeleteAccountPopupState extends ConsumerState<DeleteAccountPopup> {
  final TextEditingController _controller = TextEditingController();

  String? error;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.9),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(
            child: SizedBox(
              width: SMALL_LAYOUT / 1.7,
              child: Card(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Delete account",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error),
                          ),
                          IconButton(
                            onPressed: () {
                              _dismiss(context);
                            },
                            icon: const Icon(Icons.close),
                            iconSize: 35,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                          "Are you sure you want to delete your account?\nThis action is irreversable and will remove all data associated with the account.\nTo confirm this action type \"Delete\""),
                      const SizedBox(
                        height: 6.0,
                      ),
                      TextFormField(
                        controller: _controller,
                        decoration: InputDecoration(
                            hintText: "Delete", errorText: error),
                      ),
                      const SizedBox(
                        height: 6.0,
                      ),
                      FilledButton(
                          onPressed: () {
                            _onDelete();
                          },
                          child: const Text("Confirm Delete")),
                      const SizedBox(
                        height: 16.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _dismiss(BuildContext context) {
    ref.read(overlayProvider.notifier).state = closedQuery;
  }

  _onDelete() async {
    if (_controller.text.isEmpty || _controller.text != "Delete") {
      setState(() {
        error = "Field doesn't match";
      });

      return;
    }
    if (await ref.read(authProvider).deleteAccount()) {
      ref.invalidate(authProvider);
    } else if (mounted) {
      showSnack(context, "Failed to delete account");
    }
  }
}
