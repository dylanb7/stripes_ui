import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/auth_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/route_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StripesConfig config = ref.watch(configProvider);
    final subNotifier = ref.watch(subHolderProvider);
    if (subNotifier.isLoading) {
      return const LoadingWidget();
    }
    final SubUser? current = subNotifier.valueOrNull?.selected;
    return RefreshWidget(
      depth: RefreshDepth.authuser,
      scrollable: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: AppPadding.large,
            ),
            Row(children: [
              const SizedBox(
                width: AppPadding.large,
              ),
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
                textAlign: TextAlign.left,
              ),
              const Spacer(),
              TextButton(
                  onPressed: () async {
                    await ref.read(authProvider).logOut();
                    ref.invalidate(routeProvider);
                  },
                  child: Text(context.translate.logOutButton)),
              const SizedBox(
                width: AppPadding.large,
              ),
            ]),
            const Divider(
              endIndent: AppPadding.small,
              indent: AppPadding.small,
            ),
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
                context.pushNamed(RouteName.USERS);
              },
            ),
            const Divider(
              endIndent: AppPadding.small,
              indent: AppPadding.small,
            ),
            if (config.hasSymptomEditing) ...[
              ListTile(
                dense: false,
                visualDensity: VisualDensity.comfortable,
                title: const Text("Symptoms"),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  context.pushNamed(RouteName.SYMPTOMS);
                },
              ),
              const Divider(
                endIndent: AppPadding.small,
                indent: AppPadding.small,
              ),
              /*ListTile(
                dense: false,
                visualDensity: VisualDensity.comfortable,
                title: const Text("Settings"),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  context.pushNamed(RouteName.SETTINGS);
                },
              ),*/
            ],
            const SizedBox(
              height: AppPadding.medium,
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
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
          child: Center(
            child: SizedBox(
              width: Breakpoint.small.value,
              child: Card(
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.all(Radius.circular(AppRounding.small))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.small,
                      vertical: AppPadding.medium),
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
                        height: AppPadding.small,
                      ),
                      const Text(
                          "Are you sure you want to delete your account?\nThis action is irreversable and will remove all data associated with the account.\nTo confirm this action type \"Delete\""),
                      const SizedBox(
                        height: AppPadding.small,
                      ),
                      TextFormField(
                        controller: _controller,
                        decoration: InputDecoration(
                            hintText: "Delete", errorText: error),
                      ),
                      const SizedBox(
                        height: AppPadding.small,
                      ),
                      FilledButton(
                          onPressed: () {
                            _onDelete();
                          },
                          child: const Text("Confirm Delete")),
                      const SizedBox(
                        height: AppPadding.large,
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
    ref.read(overlayProvider.notifier).state = closedOverlay;
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
