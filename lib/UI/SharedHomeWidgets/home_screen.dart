import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_ui/Providers/sub_provider.dart';
import 'package:stripes_ui/UI/PatientManagement/add_first_patient.dart';
import 'package:stripes_ui/UI/SharedHomeWidgets/tab_view.dart';

import '../../Providers/overlay_provider.dart';

@immutable
class NavPath {
  final TabOption option;
  const NavPath({required this.option});
}

class Home extends ConsumerWidget {
  final NavPath path;

  const Home({required this.path, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(overlayProvider);
    final AsyncValue<SubState> subNotif = ref.watch(subHolderProvider);

    if (subNotif.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (subNotif.hasError) {}
    final SubState state = subNotif.value!;
    final bool empty = state.subUsers.isEmpty;
    return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: empty ||
                  state.selected == null ||
                  SubUser.isEmpty((state.selected!))
              ? CreatePatient()
              : Stack(
                  children: [
                    StripesTabView(selected: path.option),
                    if (overlay.widget != null) overlay.widget!
                  ],
                ),
        ));
  }
}
