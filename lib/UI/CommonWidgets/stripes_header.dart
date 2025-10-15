import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class StripesHeader extends StatefulWidget {
  final bool isLoading, hasEntry;

  final Alignment alignment;

  final Fit fit;

  const StripesHeader({
    this.isLoading = false,
    this.hasEntry = true,
    this.alignment = Alignment.centerLeft,
    this.fit = Fit.contain,
    super.key,
  });

  @override
  State<StripesHeader> createState() => StripesHeaderState();
}

class StripesHeaderState extends State<StripesHeader> {
  late final headerFile = FileLoader.fromAsset(
      "packages/stripes_ui/assets/rive/stripes_header.riv",
      riveFactory: Factory.rive);

  ViewModelInstanceTrigger? _checkTrigger;

  ViewModelInstanceBoolean? _loadingBool;

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: headerFile,
      builder: (context, state) {
        switch (state) {
          case RiveLoading():
            return Container();
          case RiveLoaded():
            return RiveWidget(
                alignment: widget.alignment,
                fit: widget.fit,
                controller: state.controller);
          case RiveFailed():
            return Container();
        }
      },
      onLoaded: (state) {
        ViewModel? model = state.file.viewModelByName("HeaderModel");
        ViewModelInstance? instance = model?.createInstance();

        instance?.color("CheckColor")?.value =
            Theme.of(context).colorScheme.secondary;
        instance?.color("TextColor")?.value = Theme.of(context).primaryColor;
        instance?.boolean("hasEntry")?.value = widget.hasEntry;

        _loadingBool = instance?.boolean("Loading");
        _loadingBool?.value = widget.isLoading;
        _checkTrigger = instance?.trigger("Check");
        state.controller.stateMachine.bindViewModelInstance(instance!);
        state.controller.artboard.bindViewModelInstance(instance);
      },
    );
  }

  void trigger() {
    _checkTrigger?.trigger();
  }

  void setLoading({required bool isLoading}) {
    /*setState(() {
      _loadingBool?.value = isLoading;
    });*/
  }
}
