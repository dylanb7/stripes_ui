import 'package:flutter/material.dart';

InputDecoration formFieldDecoration(
    {IconData? prefix,
    bool clearable = true,
    required String hintText,
    String? errorText,
    Widget? suffix,
    required TextEditingController controller}) {
  return InputDecoration(
    prefixIcon: prefix == null ? null : Icon(prefix),
    suffixIcon: suffix ??
        (clearable
            ? _BuildWhen(
                controller.text.isNotEmpty
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          controller.clear();
                        },
                        icon: const Icon(
                          Icons.clear,
                        ))
                    : SizedBox.fromSize(
                        size: Size.zero,
                      ),
                controller)
            : null),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelText: hintText,
    errorText: errorText,
    errorMaxLines: 1,
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(5.0),
      ),
    ),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(5.0),
      ),
    ),
  );
}

class _BuildWhen extends StatefulWidget {
  final ValueNotifier notif;

  final Widget child;

  const _BuildWhen(this.child, this.notif);
  @override
  State<StatefulWidget> createState() {
    return _BuildWhenState();
  }
}

class _BuildWhenState extends State<_BuildWhen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notif.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
