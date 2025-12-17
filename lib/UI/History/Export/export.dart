import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:stripes_ui/Providers/History/display_data_provider.dart';
import 'package:stripes_ui/Providers/Navigation/sheet_provider.dart';

import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/History/Export/export_options_sheet.dart';
import 'package:stripes_ui/Util/Widgets/easy_snack.dart';
import 'package:stripes_ui/Util/extensions.dart';
import 'package:stripes_ui/Util/Design/paddings.dart';
import 'package:stripes_ui/config.dart';
import 'package:stripes_ui/entry.dart';
import 'package:path_provider/path_provider.dart';

class Export extends ConsumerWidget {
  const Export({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Response>> available =
        ref.watch(availableStampsProvider);
    final List<Response> availableStamps = available.valueOrNull ?? [];
    final ExportAction? exportFunc = ref.watch(configProvider).export;

    return IconButton(
      onPressed:
          available.isLoading || availableStamps.isEmpty || exportFunc == null
              ? null
              : () {
                  ref.read(sheetControllerProvider).show(
                        context: context,
                        scrollControlled: true,
                        child: (context) =>
                            ExportOptionsSheet(responses: availableStamps),
                      );
                },
      icon: const Icon(
        Icons.ios_share,
      ),
      tooltip: 'Export',
    );
  }
}

Future<void> fileShare(BuildContext context, List<Response> responses,
    ExportType exportType) async {
  if (kIsWeb) {
    if (context.mounted) {
      showSnack(context, "Download not supported");
    }
    return;
  }

  final RenderBox? box = context.findRenderObject() as RenderBox?;

  String? detailsCsv;
  String? testsCsv;

  final List<DetailResponse> detailResponses =
      responses.whereType<DetailResponse>().toList();

  const List<String> detailHeaders = [
    "id",
    "date",
    "group",
    "type",
    "prompt",
    "response",
    "description"
  ];
  List<List<dynamic>> detailRows = [];

  String parseResponse(Response response) {
    if (response is NumericResponse) {
      return '${response.response}';
    }
    if (response is OpenResponse) {
      return response.response;
    }
    if (response is MultiResponse) {
      return response.question.choices[response.index];
    }
    if (response is AllResponse) {
      return response.choices.join("; ");
    }
    return "Selected";
  }

  for (DetailResponse detailResponse in detailResponses) {
    final String dateString = dateFromStamp(detailResponse.stamp).toString();
    for (Response response in detailResponse.responses) {
      detailRows.add([
        detailResponse.id,
        dateString,
        detailResponse.group,
        response.type,
        response.question.prompt,
        parseResponse(response),
        detailResponse.description
      ]);
    }
  }
  if (detailRows.isNotEmpty) {
    detailRows.insert(0, detailHeaders);
    detailsCsv = const ListToCsvConverter().convert(detailRows);
  }
  final List<BlueDyeResp> blueDyeResponses =
      responses.whereType<BlueDyeResp>().toList();

  const List<String> blueDyeHeaders = [
    "id",
    "meal start",
    "meal duration",
    "brown bms",
    "blue bms",
    "transit time",
    "lag phase",
  ];

  List<List<dynamic>> blueDyeRows = [];

  for (BlueDyeResp blueDyeResponse in blueDyeResponses) {
    blueDyeRows.add([
      blueDyeResponse.id,
      dateToStamp(blueDyeResponse.startEating).toString(),
      blueDyeResponse.eatingDuration.toString(),
      blueDyeResponse.normalBowelMovements,
      blueDyeResponse.blueBowelMovements,
      blueDyeResponse.firstBlue
          .difference(
              blueDyeResponse.startEating.add(blueDyeResponse.eatingDuration))
          .toString(),
      blueDyeResponse.lastBlue.difference(blueDyeResponse.firstBlue).toString(),
    ]);
  }

  if (blueDyeRows.isNotEmpty) {
    blueDyeRows.insert(0, blueDyeHeaders);
    testsCsv = const ListToCsvConverter().convert(blueDyeRows);
  }

  if (detailsCsv == null && testsCsv == null) return;

  final Directory tempDir = await getTemporaryDirectory();
  File? detailsFile, testsFile;

  if (detailsCsv != null) {
    detailsFile = File('${tempDir.path}/detail_responses.csv');
    await detailsFile.writeAsString(detailsCsv);
  }
  if (testsCsv != null) {
    testsFile = File('${tempDir.path}/test_responses.csv');
    await testsFile.writeAsString(testsCsv);
  }

  await Share.shareXFiles([
    if (detailsFile != null) XFile(detailsFile.path),
    if (testsFile != null) XFile(testsFile.path)
  ], sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  await detailsFile?.delete();
  await testsFile?.delete();
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

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
        child: Center(
            child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRounding.small),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Padding(
              padding: const EdgeInsets.all(AppPadding.small),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.translate.exportName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 35,
                            ))
                      ]),
                  const SizedBox(
                    height: AppPadding.small,
                  ),
                  Text(
                    context.translate.exportDialog,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: AppPadding.small,
                  ),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(
                      height: AppPadding.small,
                    )
                  ],
                  if (!loading && !done)
                    FilledButton(
                        child: Text(context.translate
                            .recordCount(widget.responses.length)),
                        onPressed: () async {
                          setState(() {
                            errorMessage = null;
                            loading = true;
                          });

                          try {
                            await exportFunc!(
                                context, widget.responses, ExportType.menu);
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                errorMessage = context.translate.uploadFail;
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
                  if (loading) const LoadingWidget(),
                  if (done)
                    FilledButton(
                        child: Text(context.translate.uploadDone),
                        onPressed: () {
                          Navigator.of(context).pop();
                        })
                ],
              )),
        )));
  }
}
