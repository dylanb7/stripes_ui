import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/event_frequency.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_widget.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/palette.dart';

// ignore: constant_identifier_names
const double SIDE_BY_SIDE = SMALL_LAYOUT * 1.5;

class EventDisplay extends StatelessWidget {
  const EventDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= SIDE_BY_SIDE) {
      return Padding(
        padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(child: EventFrequency()),
            VerticalDivider(
              width: 30,
              thickness: 2.0,
              color: darkBackgroundText,
            ),
            Expanded(
              child: GraphWidget(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
        child: SizedBox(
          width: min(width, SMALL_LAYOUT),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [EventFrequency(), GraphWidget()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
