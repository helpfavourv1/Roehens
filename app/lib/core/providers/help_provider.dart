import 'dart:ui';

import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/providers/safe_notifier.dart';
import 'package:roehens/core/services/help_catalog.dart';

/// Reads one bundled file. The composition root passes the asset bundle's
/// reader, so core stays free of Flutter's services library.
typedef HelpAssetLoader = Future<String> Function(String path);

class HelpState {
  const HelpState({this.catalog, this.strings, this.error});

  /// Null until the structure has been read, or when it could not be.
  final HelpCatalog? catalog;
  final HelpStrings? strings;
  final AppError? error;

  bool get isReady => catalog != null && strings != null;
}

/// The bundled Help content in the person's language, with English behind it.
/// Content is read from assets only: no backend, no network.
class HelpProvider extends SafeValueNotifier<HelpState> {
  HelpProvider({required this._loader, required this._logger})
    : super(const HelpState());

  static const String structurePath = 'assets/help/help_structure.json';
  static const String stringsDirectory = 'assets/help/strings';
  static const String fallbackTag = 'en';

  final HelpAssetLoader _loader;
  final LoggerContract _logger;

  HelpCatalog? _catalog;
  Map<String, String>? _english;
  String? _loadedTag;

  /// The tag of a language file for [locale]: `es_419`, `zh_Hans`, `pt_BR`
  /// or just the language, matching the ARB suffixes.
  static String tagFor(Locale locale) {
    final String? script = locale.scriptCode;
    final String? country = locale.countryCode;
    if (script != null && script.isNotEmpty) {
      return '${locale.languageCode}_$script';
    }
    if (country != null && country.isNotEmpty) {
      return '${locale.languageCode}_$country';
    }
    return locale.languageCode;
  }

  static String filePath(String tag) => '$stringsDirectory/help_$tag.json';

  /// Loads the structure once and the strings of [languageTag]. A language
  /// without a file shows English. Calling again with the same tag does
  /// nothing.
  Future<void> load({String languageTag = fallbackTag}) async {
    // English has one file whatever the region.
    if (languageTag.startsWith('en')) {
      languageTag = fallbackTag;
    }
    if (_loadedTag == languageTag && value.isReady) {
      return;
    }
    try {
      if (_catalog == null) {
        final Result<HelpCatalog> parsed = HelpCatalog.parse(
          await _loader(structurePath),
        );
        final AppError? error = parsed.errorOrNull;
        if (error != null) {
          _logger.warning('help', 'structure rejected: ${error.detail}');
          setIfAlive(HelpState(error: error));
          return;
        }
        _catalog = parsed.valueOrNull;
      }
      _english ??= HelpStrings.parseFile(await _loader(filePath(fallbackTag)));
      Map<String, String> primary = _english!;
      if (languageTag != fallbackTag) {
        try {
          primary = HelpStrings.parseFile(await _loader(filePath(languageTag)));
        } catch (_) {
          // No file for this language yet: English is shown.
          primary = const <String, String>{};
        }
      }
      _loadedTag = languageTag;
      setIfAlive(
        HelpState(
          catalog: _catalog,
          strings: HelpStrings(primary: primary, fallback: _english!),
        ),
      );
    } catch (error) {
      _logger.warning('help', 'could not read the help content', error: error);
    }
  }
}
