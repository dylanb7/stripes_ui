import 'package:flutter/material.dart';

String profileInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  if (parts.isEmpty) return '';
  final first = parts.first.characters.first;
  return (parts.length == 1 ? first : '$first${parts.last.characters.first}')
      .toUpperCase();
}

class ProfileAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const ProfileAvatar({required this.name, this.radius = 24, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = profileInitials(name);
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: initials.isEmpty
            ? Icon(Icons.person_outline, size: radius)
            : Padding(
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: radius * 0.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
