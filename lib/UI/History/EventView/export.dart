import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

import 'package:stripes_ui/Providers/history_provider.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/buttons.dart';
import 'package:stripes_ui/Util/palette.dart';
import 'package:stripes_ui/Util/text_styles.dart';
import 'package:stripes_ui/entry.dart';

class Export extends ConsumerWidget {
  const Export({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
    return IconButton(
      onPressed: () {},
      icon: const Icon(
        Icons.ios_share,
        color: darkBackgroundText,
      ),
      tooltip: 'Export',
    );
  }
}

class ExportOverlay extends ConsumerStatefulWidget {
  final List<Response> responses;

  const ExportOverlay({required this.responses, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ExportOverlayState();
}

class ExportOverlayState extends ConsumerState<ExportOverlay> {
  bool loading = false;

  bool done = false;

  @override
  Widget build(BuildContext context) {
    final exportFunc = ref.watch(exportProvider);

    return OverlayBackdrop(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Container(
              decoration: const BoxDecoration(
                  color: darkBackgroundText,
                  borderRadius: BorderRadius.all(Radius.circular(8.0))),
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Export',
                              style: lightBackgroundHeaderStyle,
                            ),
                            IconButton(
                                onPressed: () {
                                  ref.read(overlayProvider.notifier).state =
                                      closedQuery;
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: darkIconButton,
                                  size: 35,
                                ))
                          ]),
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                        'Data will be sent to the study coordinators. None of your personal information is included. If there are any changes in the future you may export again.',
                        style: lightBackgroundStyle,
                        textAlign: TextAlign.center,
                      ),
                      if (!loading && !done)
                        StripesRoundedButton(
                            text: 'Send ${widget.responses.length} entries',
                            onClick: () async {
                              setState(() {
                                loading = true;
                              });
                              await exportFunc!(widget.responses);
                              if (mounted) {
                                setState(() {
                                  loading = false;
                                  done = true;
                                });
                              }
                            }),
                      if (loading)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Sending ${widget.responses.length} entries'),
                            const CircularProgressIndicator(
                              color: darkIconButton,
                            )
                          ],
                        ),
                      if (done)
                        StripesRoundedButton(
                            text: 'Upload done',
                            onClick: () {
                              ref.read(overlayProvider.notifier).state =
                                  closedQuery;
                            })
                    ],
                  )),
            )));
  }
}
