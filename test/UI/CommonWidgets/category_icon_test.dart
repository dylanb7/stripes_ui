import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_ui/UI/CommonWidgets/category_chip.dart';
import 'package:stripes_ui/Util/Design/category_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all five category assets are bundled and decode as SVG pictures',
    () async {
      const assets = {
        'category.Meal-Time': 'meal.svg',
        'category.PAIN': 'pain.svg',
        'category.BM': 'bowel_movement.svg',
        'category.REFLUX': 'GI.svg',
        'category.NB': 'sleep.svg',
      };

      for (final entry in assets.entries) {
        final appearance = CategoryTheme.resolve(entry.key);
        expect(appearance.svgAsset, endsWith('/${entry.value}'));
        final picture = await vg.loadPicture(
          SvgAssetLoader(appearance.svgAsset!),
          null,
        );
        expect(picture.size.width, greaterThan(0));
        expect(picture.size.height, greaterThan(0));
        picture.picture.dispose();
      }
    },
  );

  testWidgets('category artwork keeps its colors and fits the requested size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: IconTheme(
            data: const IconThemeData(color: Colors.red, size: 50),
            child: CategoryIcon(
              appearance: CategoryTheme.resolve('category.Meal-Time'),
              size: 32,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.colorFilter, isNull);
    expect(svg.excludeFromSemantics, isTrue);
    expect(tester.getSize(find.byType(SvgPicture)), const Size(32, 32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit tint and standalone accessible label are supported', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: CategoryIcon(
              appearance: CategoryTheme.resolve('category.BM'),
              color: Colors.blue,
              semanticLabel: 'Bowel movement',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svg.colorFilter,
        const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
      );
      expect(find.bySemanticsLabel('Bowel movement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('custom categories retain the generic icon and stable color', (
    tester,
  ) async {
    final appearance = CategoryTheme.resolve('custom.hydration');
    expect(appearance.svgAsset, isNull);
    expect(CategoryTheme.resolve('custom.hydration').color, appearance.color);
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryIcon(
          appearance: appearance,
          size: 28,
          semanticLabel: 'Hydration',
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.category_rounded));
    expect(icon.size, 28);
    expect(icon.color, appearance.color);
    expect(icon.semanticLabel, 'Hydration');
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('category chips render illustrations and retain text labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CategoryChip(
            appearance: CategoryTheme.resolve('category.NB'),
            categoryName: 'Sleep',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
