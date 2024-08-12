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
            ? ListenableBuilder(
                listenable: controller,
                builder: (context, child) {
                  if (controller.text.isEmpty) return Container();
                  return IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      controller.clear();
                    },
                    icon: const Icon(
                      Icons.clear,
                    ),
                  );
                })
            : null),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    hintText: hintText,
    labelText: hintText,
    errorText: errorText,
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
