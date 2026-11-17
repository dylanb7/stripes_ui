<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

To try the new Blue Meal study progress UI independently of other beta features:

```dart
const config = StripesConfig.sandbox(
  betaUi: BetaUiConfig.disabled(blueDyeTest: true),
);
```

Pass this config to your existing Stripes configuration. The flag replaces the
study interface with white bordered cards, a pale background, an orange current
step, and navy completed steps. It includes organized enrollment information,
consent and preparation screens, meal entry, bowel movement logging, and a waiting
countdown. The header's info button reopens the invitation, overview, eligibility,
study flow, and definitions. Both information and **View Steps** use the shared
sheet provider and its responsive presentation. Step accordions show saved meal
details and bowel movements from their corresponding transit run above the
instructions. Records stay up to date across edits and deletions, independently
of the History date range. Opening either sheet preserves the active form and
its answers; the existing study progression remains in use.

The flag defaults to `false` in `BetaUiConfig.disabled()` and `true` in
`BetaUiConfig.enabled()`. Set `blueDyeTest: false` to retain the legacy study UI
while trying the other beta features.

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
