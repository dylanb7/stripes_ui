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

final actionProvider = StateProvider<FloatingActionButton?>((_) => null);

class Home extends ConsumerWidget {
  final NavPath path;

  const Home({required this.path, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay = ref.watch(overlayProvider);
    final SubNotifier subNotif = ref.watch(subHolderProvider);
    final empty = subNotif.users.isEmpty;
    final FloatingActionButton? button = ref.watch(actionProvider);
    return Scaffold(
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: button,
      body: empty || SubUser.isEmpty((subNotif.current))
          ? CreatePatient()
          : Stack(
              children: [
                StripesTabView(selected: path.option),
                if (overlay.widget != null) overlay.widget!
              ],
            ),
    );
  }
}
