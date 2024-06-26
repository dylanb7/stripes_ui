import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/overlay_provider.dart';
import 'package:stripes_ui/entry.dart';
import 'package:stripes_ui/l10n/app_localizations.dart';

class Export extends ConsumerWidget {
  const Export({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {},
      icon: const Icon(
        Icons.ios_share,
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

  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final exportFunc = ref.watch(configProvider).export;

    return OverlayBackdrop(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Container(
              decoration: const BoxDecoration(
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
                            Text(
                              AppLocalizations.of(context)!.exportName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            IconButton(
                                onPressed: () {
                                  ref.read(overlayProvider.notifier).state =
                                      closedQuery;
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 35,
                                ))
                          ]),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        AppLocalizations.of(context)!.exportDialog,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      if (errorMessage != null) ...[
                        Text(
                          errorMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(
                          height: 8,
                        )
                      ],
                      if (!loading && !done)
                        FilledButton(
                            child: Text(AppLocalizations.of(context)!
                                .recordCount(widget.responses.length)),
                            onPressed: () async {
                              setState(() {
                                errorMessage = null;
                                loading = true;
                              });

                              try {
                                await exportFunc!(widget.responses);
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    errorMessage = AppLocalizations.of(context)!
                                        .uploadFail;
                                    loading = false;
                                  });
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    errorMessage = null;
                                    loading = false;
                                    done = true;
                                  });
                                }
                              }
                            }),
                      if (loading) const CircularProgressIndicator(),
                      if (done)
                        FilledButton(
                            child:
                                Text(AppLocalizations.of(context)!.uploadDone),
                            onPressed: () {
                              ref.read(overlayProvider.notifier).state =
                                  closedQuery;
                            })
                    ],
                  )),
            )));
  }
}
