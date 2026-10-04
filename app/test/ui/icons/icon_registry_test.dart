import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/ui/icons/app_icons.dart';

void main() {
  test('every semantic name has a mapping', () {
    expect(AppIcons.mappedNames.toSet(), AppIconName.values.toSet());
    expect(AppIcons.mappedNames.length, AppIconName.values.length);
  });

  test('no two semantic names share a glyph', () {
    final Set<int> codePoints = <int>{};
    for (final AppIconName name in AppIconName.values) {
      final int codePoint =
          AppIcons.layers(name, AppIconWeight.bold).primary.codePoint;
      expect(codePoints.add(codePoint), isTrue, reason: '$name reuses a glyph');
    }
  });

  test('each weight resolves to its own font family', () {
    for (final AppIconName name in AppIconName.values) {
      expect(
        AppIcons.layers(name, AppIconWeight.bold).primary.fontFamily,
        'PhosphorBold',
      );
      expect(
        AppIcons.layers(name, AppIconWeight.fill).primary.fontFamily,
        'PhosphorFill',
      );
      expect(
        AppIcons.layers(name, AppIconWeight.duotone).primary.fontFamily,
        'PhosphorDuotone',
      );
    }
  });

  test('only duotone icons carry a secondary layer', () {
    for (final AppIconName name in AppIconName.values) {
      expect(AppIcons.layers(name, AppIconWeight.bold).secondary, isNull);
      expect(AppIcons.layers(name, AppIconWeight.fill).secondary, isNull);
      expect(AppIcons.layers(name, AppIconWeight.duotone).secondary, isNotNull);
    }
  });

  test('only directional icons mirror in right-to-left layouts', () {
    final Set<AppIconName> mirrored = AppIconName.values
        .where((AppIconName name) => name.mirrorsInRtl)
        .toSet();
    expect(mirrored, <AppIconName>{
      AppIconName.chevronLeft,
      AppIconName.chevronRight,
      AppIconName.back,
      AppIconName.forward,
    });
  });
}
