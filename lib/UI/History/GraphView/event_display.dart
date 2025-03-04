import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stripes_ui/UI/History/GraphView/event_frequency.dart';
import 'package:stripes_ui/UI/History/GraphView/graph_widget.dart';
import 'package:stripes_ui/Util/breakpoint.dart';

// ignore: constant_identifier_names

class EventDisplay extends StatelessWidget {
  const EventDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLarge = getBreakpoint(context).isGreaterThan(Breakpoint.large);
    final double width = MediaQuery.of(context).size.width;
    if (isLarge) {
      return const Padding(
        padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: EventFrequency()),
            VerticalDivider(
              width: 30,
              thickness: 2.0,
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
          width: min(width, Breakpoint.small.value),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [GraphWidget(), EventFrequency()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
