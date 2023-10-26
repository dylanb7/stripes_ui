import 'package:flutter/material.dart';
import 'package:stripes_ui/Util/form_input.dart';

class ObscureTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final bool shouldValidate;

  const ObscureTextField(
      {required this.hintText,
      required this.controller,
      required this.validator,
      this.shouldValidate = true,
      this.autofillHints,
      super.key});

  @override
  State<StatefulWidget> createState() {
    return _ObscureTextFieldState();
  }
}

class _ObscureTextFieldState extends State<ObscureTextField> {
  bool _obscure = true;

  bool _notEmpty = false;

  @override
  void initState() {
    widget.controller.addListener(() {
      final bool notEmpty = widget.controller.text.isNotEmpty;
      if (_notEmpty != notEmpty) {
        setState(() {
          _notEmpty = notEmpty;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget suffix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _obscure = !_obscure;
              });
            },
            icon: _obscure
                ? const Icon(
                    Icons.visibility,
                  )
                : const Icon(
                    Icons.visibility_off,
                  )),
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            widget.controller.clear();
          },
          icon: const Icon(
            Icons.clear,
          ),
        ),
      ],
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      autovalidateMode: widget.shouldValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      autofillHints: widget.autofillHints,
      decoration: formFieldDecoration(
          hintText: widget.hintText,
          controller: widget.controller,
          prefix: Icons.lock_outline,
          clearable: false,
          suffix: widget.controller.text.isNotEmpty ? suffix : null),
    );
  }
}
