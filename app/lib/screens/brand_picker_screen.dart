import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/brand_picker.dart';

/// Opens the brand list; completes with the chosen brand, or null when the
/// person goes back.
Future<CameraBrandProfile?> openBrandPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return Navigator.of(context).push<CameraBrandProfile>(
    AppPageRoute<CameraBrandProfile>(
      reduceMotion: context.reduceMotion,
      builder: (BuildContext _) => BrandPickerScreen(selectedId: selectedId),
    ),
  );
}

/// The bundled brand database, alphabetical with sticky letter headers and a
/// search field that scrolls away with the list.
class BrandPickerScreen extends StatelessWidget {
  const BrandPickerScreen({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<CameraBrandProfile> brands = AppScope.of(context)
        .profiles
        .brands;
    return AppScaffold(
      navBar: AppNavBar(
        title: l10n.brandTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.actionBack,
      ),
      body: BrandPicker(
        brands: brands,
        selectedId: selectedId,
        searchLabel: l10n.brandSearch,
        noResultsTitle: l10n.brandNoResults,
        noResultsMessage: l10n.brandNoResultsHint,
        verifiedLabel: l10n.brandVerified,
        onSelected: (CameraBrandProfile brand) =>
            Navigator.of(context).pop(brand),
      ),
    );
  }
}
