import 'package:flutter/material.dart';

class ScreenManager extends StatefulWidget {
  final ScreenController controller;

  const ScreenManager({required this.controller, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ScreenManagerState();
  }
}

class _ScreenManagerState extends State<ScreenManager> {
  @override
  Widget build(BuildContext context) {
    return widget.controller.getScreen();
  }
}

class ScreenController extends ChangeNotifier {
  int index = 0;

  final List<Widget> widgets;

  ScreenController(this.widgets);

  next() {
    if (hasNext()) {
      index++;
      notifyListeners();
    }
  }

  previous() {
    if (hasPrev()) {
      index--;
      notifyListeners();
    }
  }

  Widget getScreen() => widgets[index];

  bool hasNext() => index < widgets.length - 1;
  bool hasPrev() => index > 0;
}
