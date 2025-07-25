import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_ui/Providers/history_provider.dart';

import 'package:stripes_ui/Util/date_helper.dart';
import 'package:stripes_ui/Util/paddings.dart';

class TimeSpanInfo extends ConsumerWidget {
  const TimeSpanInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Response> stamps =
        ref.watch(availibleStampsProvider).valueOrNull?.visible ?? [];

    final double width = MediaQuery.of(context).size.width;

    if (stamps.isEmpty) {
      return Center(
        child: Text(
          "No Data Recorded",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.xl),
      child: Center(
        child: SizedBox(
          height: 70,
          width: min(450, width),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRounding.large)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Events',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text('${stamps.length}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold))
                  ],
                )),
                const VerticalDivider(
                  width: AppPadding.tiny,
                  thickness: 1,
                  indent: AppPadding.xl,
                  endIndent: 2,
                  color: Colors.black54,
                ),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Oldest',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${_respToDateStr(stamps.last, context)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    )
                  ],
                )),
                const VerticalDivider(
                  width: AppPadding.tiny,
                  thickness: 1,
                  indent: AppPadding.xl,
                  endIndent: 2,
                  color: Colors.black54,
                ),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Newest',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${_respToDateStr(stamps.first, context)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    )
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _respToDateStr(Response res, BuildContext context) {
    final DateTime date = dateFromStamp(res.stamp);
    return dateToMDY(date, context);
  }
}
