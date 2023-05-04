import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/PatientManagement/add_first_patient.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/tab_view.dart';
import 'package:stripes_ui/Util/constants.dart';

import '../../Providers/overlay_provider.dart';
import '../../Util/palette.dart';

@immutable
class NavPath {
  final TabOption option;
  const NavPath({required this.option});
}

final actionProvider = StateProvider<FloatingActionButton?>((_) => null);

final isSmallProvider = StateProvider<bool>((_) => false);

class Home extends ConsumerWidget {
  final NavPath path;

  const Home({required this.path, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(overlayProvider);
    final SubUser currentSub = ref.watch(subHolderProvider).current;
    final FloatingActionButton? button = ref.watch(actionProvider);
    return _SmallUpdater(
      child: Scaffold(
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterFloat,
        floatingActionButton: button,
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundStrong, backgroundLight])),
          child: SubUser.isEmpty((currentSub))
              ? CreatePatient()
              : Stack(
                  children: [
                    StripesTabView(selected: path.option),
                    if (overlay.widget != null) overlay.widget!
                  ],
                ),
        ),
      ),
    );
  }
}

class _SmallUpdater extends ConsumerWidget {
  final Widget child;

  const _SmallUpdater({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          final bool isSmall = ref.read(isSmallProvider);
          final bool newVal = constraints.maxWidth < SMALL_LAYOUT;
          if (isSmall != newVal) {
            ref.read(isSmallProvider.notifier).state = newVal;
          }
        });
        return child;
      },
    );
  }
}
