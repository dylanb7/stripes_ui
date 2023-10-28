import 'package:flutter/material.dart';

class ButtonLoadingIndicator extends StatelessWidget {
  const ButtonLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.0,
      height: 20.0,
      padding: const EdgeInsets.all(2.0),
      child: const CircularProgressIndicator(
        strokeWidth: 5.0,
      ),
    );
  }
}
