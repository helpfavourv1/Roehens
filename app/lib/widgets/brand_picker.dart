import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/ui/components/app_badge.dart';
import 'package:roehens/ui/components/app_empty_state.dart';
import 'package:roehens/ui/components/app_letter_header.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';

/// Camera brands in alphabetical groups under sticky letter headers. The search
/// field is the first thing in the list, so it scrolls away with the content.
class BrandPicker extends StatefulWidget {
  const BrandPicker({
    super.key,
    required this.brands,
    required this.onSelected,
    required this.searchLabel,
    required this.noResultsTitle,
    this.selectedId,
    this.verifiedLabel,
    this.noResultsMessage,
  });

  final List<CameraBrandProfile> brands;
  final ValueChanged<CameraBrandProfile> onSelected;
  final String? selectedId;
  final String searchLabel;
  final String noResultsTitle;
  final String? noResultsMessage;

  /// Shown as a badge on brands whose paths were checked on real cameras.
  final String? verifiedLabel;

  /// The group letter for a brand name; anything that is not a cased letter
  /// goes under `#`.
  static String letterFor(String name) {
    if (name.isEmpty) {
      return '#';
    }
    final String first = name.substring(0, 1);
    final String upper = first.toUpperCase();
    return upper == first.toLowerCase() ? '#' : upper;
  }

  /// Brands matching [query] (by name, case-insensitive), grouped and sorted.
  static List<MapEntry<String, List<CameraBrandProfile>>> group(
    List<CameraBrandProfile> brands,
    String query,
  ) {
    final String needle = query.trim().toLowerCase();
    final List<CameraBrandProfile> matching =
        <CameraBrandProfile>[
          for (final CameraBrandProfile b in brands)
            if (needle.isEmpty || b.displayName.toLowerCase().contains(needle))
              b,
        ]..sort(
          (CameraBrandProfile a, CameraBrandProfile b) => a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase()),
        );
    final Map<String, List<CameraBrandProfile>> byLetter =
        <String, List<CameraBrandProfile>>{};
    for (final CameraBrandProfile brand in matching) {
      byLetter
          .putIfAbsent(
            letterFor(brand.displayName),
            () => <CameraBrandProfile>[],
          )
          .add(brand);
    }
    final List<String> letters = byLetter.keys.toList()
      ..sort((String a, String b) {
        if (a == '#') {
          return 1;
        }
        if (b == '#') {
          return -1;
        }
        return a.compareTo(b);
      });
    return <MapEntry<String, List<CameraBrandProfile>>>[
      for (final String letter in letters)
        MapEntry<String, List<CameraBrandProfile>>(letter, byLetter[letter]!),
    ];
  }

  @override
  State<BrandPicker> createState() => _BrandPickerState();
}

class _BrandPickerState extends State<BrandPicker> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.allMd,
            child: AppTextField(
              controller: _query,
              hint: widget.searchLabel,
              semanticLabel: widget.searchLabel,
              leadingIcon: AppIconName.search,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _query,
          builder: (BuildContext context, TextEditingValue value, Widget? _) {
            final List<MapEntry<String, List<CameraBrandProfile>>> groups =
                BrandPicker.group(widget.brands, value.text);
            if (groups.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: AppIconName.search,
                  title: widget.noResultsTitle,
                  message: widget.noResultsMessage,
                ),
              );
            }
            return SliverMainAxisGroup(
              slivers: <Widget>[
                for (final MapEntry<String, List<CameraBrandProfile>> entry
                    in groups)
                  AppLetterHeader.group(
                    letter: entry.key,
                    sliver: SliverList.builder(
                      itemCount: entry.value.length,
                      itemBuilder: (BuildContext context, int index) {
                        final CameraBrandProfile brand = entry.value[index];
                        return AppListRow(
                          title: brand.displayName,
                          selected: brand.id == widget.selectedId,
                          onTap: () => widget.onSelected(brand),
                          trailing:
                              brand.verified && widget.verifiedLabel != null
                              ? AppBadge(
                                  widget.verifiedLabel!,
                                  tone: AppBadgeTone.success,
                                )
                              : null,
                          showChevron:
                              !(brand.verified && widget.verifiedLabel != null),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
