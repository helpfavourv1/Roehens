import 'package:flutter/widgets.dart';
import 'package:roehens/app/app_providers.dart';
import 'package:roehens/app/app_scope.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/l10n/app_localizations.dart';
import 'package:roehens/screens/cameras_screen.dart';
import 'package:roehens/screens/home_screen.dart';
import 'package:roehens/ui/components/app_bottom_bar.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/widgets/banner_ad_slot.dart';

/// The frame of the three main tabs: Live, Cameras and Settings.
///
/// It hosts the banner ad slot above the bottom bar, on Live only (C8.4). The
/// bar and the slot collapse together under the keyboard. Each tab keeps its
/// own state while another is shown.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.settingsBuilder,
    required this.onAddCamera,
    required this.onFindCameras,
    required this.onEditCamera,
  });

  /// The Settings tab (batch P5C); the app shell passes it in.
  final WidgetBuilder settingsBuilder;
  final VoidCallback onAddCamera;
  final VoidCallback onFindCameras;
  final ValueChanged<Camera> onEditCamera;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _live = 0;
  final ValueNotifier<int> _index = ValueNotifier<int>(_live);

  @override
  void dispose() {
    _index.dispose();
    super.dispose();
  }

  bool _keyboardUp = false;
  int _widthDp = 0;

  /// Tells the ad slot about the keyboard and the width it may use. The
  /// provider notifies its listeners, so this runs after the frame.
  void _reportLayout(AppProviders app, MediaQueryData media) {
    final bool keyboard = media.viewInsets.bottom > 0;
    final int width = media.size.width.floor();
    if (keyboard == _keyboardUp && width == _widthDp) {
      return;
    }
    _keyboardUp = keyboard;
    _widthDp = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      app.adState.setKeyboardVisible(visible: keyboard);
      app.adState.setAvailableWidth(width);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppProviders app = AppScope.of(context);
    _reportLayout(app, MediaQuery.of(context));
    return ValueListenableBuilder<int>(
      valueListenable: _index,
      builder: (BuildContext context, int index, Widget? _) {
        return AppScaffold(
          body: IndexedStack(
            index: index,
            children: <Widget>[
              HomeScreen(
                isActive: index == _live,
                onAddCamera: widget.onAddCamera,
                onFindCameras: widget.onFindCameras,
                onEditCamera: widget.onEditCamera,
              ),
              CamerasScreen(
                onAddCamera: widget.onAddCamera,
                onEditCamera: widget.onEditCamera,
              ),
              Builder(builder: widget.settingsBuilder),
            ],
          ),
          bottomEmbed: index == _live
              ? BannerAdSlot(
                  state: app.adState,
                  viewBuilder: (Object view) =>
                      view is Widget ? view : const SizedBox.shrink(),
                )
              : null,
          bottomBar: AppBottomBar(
            selectedIndex: index,
            onSelected: (int next) => _index.value = next,
            items: <AppBottomBarItem>[
              AppBottomBarItem(
                icon: AppIconName.layoutGrid4,
                label: l10n.tabLive,
              ),
              AppBottomBarItem(
                icon: AppIconName.cameraDome,
                label: l10n.tabCameras,
              ),
              AppBottomBarItem(
                icon: AppIconName.settings,
                label: l10n.tabSettings,
              ),
            ],
          ),
        );
      },
    );
  }
}
