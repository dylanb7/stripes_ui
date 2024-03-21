import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';

import 'package:stripes_ui/Util/constants.dart';

import 'add_user_widget.dart';
import 'user_view.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double itemWidth = SMALL_LAYOUT / 1.5;
    final OverlayQuery overlay = ref.watch(overlayProvider);
    final subNotifier = ref.watch(subHolderProvider);
    if (subNotifier.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final List<SubUser> subUsers = subNotifier.valueOrNull?.subUsers ?? [];
    final SubUser? current = subNotifier.valueOrNull?.selected;
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Text(
                  'Patient Profiles',
                  maxLines: 2,
                  style: Theme.of(context).textTheme.headlineMedium,
                )),
                IconButton(
                    onPressed: () {
                      context.pop();
                    },
                    iconSize: 40,
                    icon: const Icon(
                      Icons.close,
                    ))
              ],
            ),
            const SizedBox(
              height: 12.0,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  children: subUsers
                      .map<Widget>(
                        (user) => SizedBox(
                          width: itemWidth,
                          child: UserView(
                            subUser: user,
                            selected: user.uid == current?.uid,
                          ),
                        ),
                      )
                      .toList()
                    ..add(
                      const SizedBox(
                        width: itemWidth,
                        child: AddUserWidget(),
                      ),
                    ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (overlay.widget != null) overlay.widget!
    ]);
  }
}
