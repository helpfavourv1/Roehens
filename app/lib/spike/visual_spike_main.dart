// Temporary entry point for checkpoint A1 (batch P4E). It shows the component
// library on a real phone so the finish can be judged by eye. It uses no
// services and no stored data, and it is deleted in batch P8.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/providers/ad_state_provider.dart';
import 'package:roehens/ui/components/app_badge.dart';
import 'package:roehens/ui/components/app_banner.dart';
import 'package:roehens/ui/components/app_bottom_bar.dart';
import 'package:roehens/ui/components/app_button.dart';
import 'package:roehens/ui/components/app_card.dart';
import 'package:roehens/ui/components/app_chip.dart';
import 'package:roehens/ui/components/app_dialog.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/app_list_row.dart';
import 'package:roehens/ui/components/app_nav_bar.dart';
import 'package:roehens/ui/components/app_page_route.dart';
import 'package:roehens/ui/components/app_progress.dart';
import 'package:roehens/ui/components/app_scaffold.dart';
import 'package:roehens/ui/components/app_section.dart';
import 'package:roehens/ui/components/app_segmented_control.dart';
import 'package:roehens/ui/components/app_sheet.dart';
import 'package:roehens/ui/components/app_slider.dart';
import 'package:roehens/ui/components/app_switch.dart';
import 'package:roehens/ui/components/app_text_field.dart';
import 'package:roehens/ui/components/app_toast.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/app_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';
import 'package:roehens/widgets/banner_ad_slot.dart';
import 'package:roehens/widgets/brand_picker.dart';
import 'package:roehens/widgets/camera_grid.dart';
import 'package:roehens/widgets/camera_tile.dart';
import 'package:roehens/widgets/fullscreen_controls.dart';
import 'package:roehens/widgets/grid_layout_picker.dart';
import 'package:roehens/widgets/ptz_pad.dart';
import 'package:roehens/widgets/ptz_speed_control.dart';
import 'package:roehens/widgets/stream_status_pill.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the system bars; the scaffold sets their icon colors.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const VisualSpikeApp());
}

/// What the person is trying out, shared by the whole spike.
class _Controls {
  final ValueNotifier<Brightness> brightness = ValueNotifier<Brightness>(
    Brightness.dark,
  );
  final ValueNotifier<bool> rtl = ValueNotifier<bool>(false);
  final ValueNotifier<double> textScale = ValueNotifier<double>(1);
  final ValueNotifier<int> section = ValueNotifier<int>(0);
  final ValueNotifier<int> tab = ValueNotifier<int>(0);
  final ValueNotifier<AdSlotState> ad = ValueNotifier<AdSlotState>(
    AdSlotState.collapsed,
  );

  Listenable get look =>
      Listenable.merge(<Listenable>[brightness, rtl, textScale]);
}

class VisualSpikeApp extends StatelessWidget {
  const VisualSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final _Controls controls = _Controls();
    return WidgetsApp(
      color: AppTokensData.resolve(brightness: Brightness.dark)
          .colors
          .bgPrimary,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return AppPageRoute<T>(settings: settings, builder: builder);
      },
      // The tokens wrap the whole navigator, so sheets, dialogs and toasts
      // (drawn in the overlay) can read them too.
      builder: (BuildContext context, Widget? child) {
        return ListenableBuilder(
          listenable: controls.look,
          builder: (BuildContext context, Widget? _) {
            return Directionality(
              textDirection: controls.rtl.value
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: controls.textScale.value,
                maxScaleFactor: controls.textScale.value,
                child: AppTokens(
                  data: AppTokensData.resolve(
                    brightness: controls.brightness.value,
                  ),
                  child: child!,
                ),
              ),
            );
          },
        );
      },
      home: _SpikeHome(controls: controls),
    );
  }
}

class _SpikeHome extends StatelessWidget {
  const _SpikeHome({required this.controls});

  final _Controls controls;

  static const List<String> _sections = <String>[
    'Components',
    'Tiles',
    'PTZ',
    'Brands',
    'Overlays',
    'Arabic',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controls.rtl,
      builder: (BuildContext context, Widget? _) {
        return ValueListenableBuilder<int>(
          valueListenable: controls.tab,
          builder: (BuildContext context, int tab, Widget? _) {
            return AppScaffold(
              navBar: AppNavBar(
                leading: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                  ),
                  child: Text(
                    'Roehens',
                    style: context.type.title1.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                title: controls.rtl.value ? 'عرض التصميم' : 'Design check',
                actions: <Widget>[
                  AppIconButton(
                    icon: AppIconName.settings,
                    semanticLabel: 'Settings',
                    onPressed: () {},
                  ),
                ],
              ),
              body: Column(
                children: <Widget>[
                  _LookBar(controls: controls),
                  _SectionBar(controls: controls, sections: _sections),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: controls.section,
                      builder: (BuildContext context, int section, Widget? _) {
                        return switch (section) {
                          0 => const _ComponentsSection(),
                          1 => const _TilesSection(),
                          2 => _PtzSection(controls: controls),
                          3 => const _BrandsSection(),
                          4 => _OverlaysSection(controls: controls),
                          _ => const _ArabicSection(),
                        };
                      },
                    ),
                  ),
                ],
              ),
              bottomEmbed: BannerAdSlot(
                state: controls.ad,
                viewBuilder: (Object view) => Center(
                  child: Text(
                    'Ad slot (mock)',
                    style: context.type.footnote.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ),
              ),
              bottomBar: AppBottomBar(
                selectedIndex: tab,
                onSelected: (int i) => controls.tab.value = i,
                items: const <AppBottomBarItem>[
                  AppBottomBarItem(icon: AppIconName.cameraDome, label: 'Live'),
                  AppBottomBarItem(
                    icon: AppIconName.layoutGrid4,
                    label: 'Cameras',
                    badge: '3',
                  ),
                  AppBottomBarItem(
                    icon: AppIconName.settings,
                    label: 'Settings',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Switches for the things A1 needs to see: theme, direction, text size.
class _LookBar extends StatelessWidget {
  const _LookBar({required this.controls});

  final _Controls controls;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ListenableBuilder(
        listenable: controls.look,
        builder: (BuildContext context, Widget? _) {
          return Row(
            children: <Widget>[
              AppChip(
                label: 'Dark',
                icon: AppIconName.moon,
                selected: controls.brightness.value == Brightness.dark,
                onTap: () => controls.brightness.value = Brightness.dark,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: 'Light',
                icon: AppIconName.sun,
                selected: controls.brightness.value == Brightness.light,
                onTap: () => controls.brightness.value = Brightness.light,
              ),
              const SizedBox(width: AppSpacing.md),
              AppChip(
                label: 'RTL',
                icon: AppIconName.globe,
                selected: controls.rtl.value,
                onTap: () => controls.rtl.value = !controls.rtl.value,
              ),
              const SizedBox(width: AppSpacing.md),
              for (final double scale in <double>[1, 1.3, 2, 3.1]) ...<Widget>[
                AppChip(
                  label: '${scale}x',
                  selected: controls.textScale.value == scale,
                  onTap: () => controls.textScale.value = scale,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.controls, required this.sections});

  final _Controls controls;
  final List<String> sections;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      child: ValueListenableBuilder<int>(
        valueListenable: controls.section,
        builder: (BuildContext context, int current, Widget? _) {
          return Row(
            children: <Widget>[
              for (int i = 0; i < sections.length; i++) ...<Widget>[
                AppChip(
                  label: sections[i],
                  selected: i == current,
                  onTap: () => controls.section.value = i,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A value the section keeps for itself, without `setState`.
class _Notified<T> extends StatefulWidget {
  const _Notified({required this.initial, required this.builder});

  final T initial;
  final Widget Function(BuildContext context, T value, ValueSetter<T> set)
  builder;

  @override
  State<_Notified<T>> createState() => _NotifiedState<T>();
}

class _NotifiedState<T> extends State<_Notified<T>> {
  late final ValueNotifier<T> _value = ValueNotifier<T>(widget.initial);

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: _value,
      builder: (BuildContext context, T value, Widget? _) {
        return widget.builder(context, value, (T next) => _value.value = next);
      },
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: AppSpacing.allMd,
      children: <Widget>[
        for (final Widget child in children) ...<Widget>[
          child,
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.type.footnote.copyWith(color: context.colors.textTertiary),
    );
  }
}

/// A made-up camera picture, so tiles have something to sit on.
class _FakePicture extends StatelessWidget {
  const _FakePicture(this.hue);

  final double hue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            HSVColor.fromAHSV(1, hue, 0.45, 0.35).toColor(),
            HSVColor.fromAHSV(1, (hue + 40) % 360, 0.55, 0.6).toColor(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- components

class _ComponentsSection extends StatelessWidget {
  const _ComponentsSection();

  @override
  Widget build(BuildContext context) {
    final AppTokensData tokens = context.tokens;
    final TextEditingController name = TextEditingController(
      text: 'Garden gate',
    );
    final TextEditingController host = TextEditingController(
      text: '192.168.1.20',
    );
    final TextEditingController secret = TextEditingController(text: 'secret');
    final TextEditingController bad = TextEditingController();
    return _Page(
      children: <Widget>[
        const _Note(
          'Icon weight beside text: Bold, Fill and Duotone next to three type sizes.',
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final AppIconWeight weight
                in AppIconWeight.values) ...<Widget>[
              AppIcon(
                AppIconName.cameraDome,
                size: 24,
                color: tokens.colors.textPrimary,
                weight: weight,
                secondaryColor: tokens.colors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                weight.name,
                style: context.type.callout.copyWith(
                  color: tokens.colors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ],
        ),
        Text(
          'Title 2 (17)',
          style: context.type.title2.copyWith(color: tokens.colors.textPrimary),
        ),
        Text(
          'Body (15), the reading text of the app.',
          style: context.type.body.copyWith(color: tokens.colors.textSecondary),
        ),
        Text(
          'Footnote (13) and 1920x1080 25fps',
          style: context.type.footnote.copyWith(
            color: tokens.colors.textTertiary,
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            AppButton(label: 'Primary', onPressed: () {}),
            AppButton(
              label: 'Secondary',
              kind: AppButtonKind.secondary,
              onPressed: () {},
            ),
            AppButton(
              label: 'Tinted',
              kind: AppButtonKind.tinted,
              icon: AppIconName.plus,
              onPressed: () {},
            ),
            AppButton(
              label: 'Delete',
              kind: AppButtonKind.destructive,
              onPressed: () {},
            ),
            const AppButton(label: 'Disabled', onPressed: null),
            AppButton(label: 'Busy', isLoading: true, onPressed: () {}),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            AppChip(label: 'Retry', icon: AppIconName.refresh, onTap: () {}),
            AppChip(label: 'Selected', selected: true, onTap: () {}),
            AppChip(label: 'Remove', destructive: true, onTap: () {}),
            const AppBadge('PRO', tone: AppBadgeTone.accent),
            const AppBadge('3'),
            const AppBadge('Verified', tone: AppBadgeTone.success),
          ],
        ),
        Row(
          children: <Widget>[
            AppIconButton(
              icon: AppIconName.snapshot,
              semanticLabel: 'Snapshot',
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            AppIconButton(
              icon: AppIconName.volumeOff,
              semanticLabel: 'Mute',
              tone: AppIconButtonTone.selected,
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 56,
              width: 80,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const _FakePicture(200),
                  Center(
                    child: AppIconButton(
                      icon: AppIconName.fullscreenEnter,
                      semanticLabel: 'Fullscreen',
                      tone: AppIconButtonTone.overVideo,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _Notified<bool>(
          initial: true,
          builder: (BuildContext context, bool on, ValueSetter<bool> set) {
            return AppSection(
              title: 'Settings look',
              footer: 'A footnote under a group of rows.',
              children: <Widget>[
                AppListRow(
                  leading: AppIconName.moon,
                  title: 'Appearance',
                  subtitle: 'Dark',
                  onTap: () {},
                ),
                AppListRow(
                  leading: AppIconName.sun,
                  title: 'Keep screen awake',
                  subtitle: 'While cameras are on screen',
                  trailing: AppSwitch(
                    value: on,
                    onChanged: set,
                    semanticLabel: 'Keep screen awake',
                  ),
                ),
                AppListRow(
                  leading: AppIconName.delete,
                  title: 'Delete all local data',
                  destructive: true,
                  onTap: () {},
                ),
              ],
            );
          },
        ),
        _Notified<String>(
          initial: 'a',
          builder:
              (BuildContext context, String value, ValueSetter<String> set) {
                return AppSegmentedControl<String>(
                  selected: value,
                  onChanged: set,
                  segments: const <AppSegment<String>>[
                    AppSegment<String>(value: 'a', label: 'System'),
                    AppSegment<String>(value: 'b', label: 'Light'),
                    AppSegment<String>(value: 'c', label: 'Dark'),
                  ],
                );
              },
        ),
        AppCard(
          onTap: () {},
          child: Row(
            children: <Widget>[
              AppIcon(AppIconName.info, size: 24, color: tokens.colors.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'A tappable card: secondary surface, hairline border, no shadow.',
                  style: context.type.body.copyWith(
                    color: tokens.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const _Note(
          'Fields. Long-press a field to try copy and paste (system menu).',
        ),
        AppTextField(controller: name, label: 'Name', hint: 'Front door'),
        AppTextField(
          controller: host,
          label: 'Address',
          forceLtr: true,
          monospace: true,
          leadingIcon: AppIconName.network,
          helperText: 'IP and ports always read left to right.',
        ),
        AppTextField(
          controller: secret,
          label: 'Password',
          obscureText: true,
          revealLabel: 'Show password',
          concealLabel: 'Hide password',
        ),
        AppTextField(
          controller: bad,
          label: 'Port',
          hint: '554',
          errorText: 'Enter a port from 1 to 65535',
        ),
        _Notified<double>(
          initial: 0.4,
          builder:
              (BuildContext context, double value, ValueSetter<double> set) {
                return AppSlider(
                  value: value,
                  onChanged: set,
                  semanticLabel: 'Volume',
                );
              },
        ),
        Row(
          children: <Widget>[
            const AppProgress.spinner(),
            const SizedBox(width: AppSpacing.md),
            const Expanded(child: AppProgress.bar(value: 0.6)),
          ],
        ),
        const AppBanner(
          message: 'Storage is not working. Cameras may not be saved.',
          tone: AppBannerTone.warning,
          actionLabel: 'Export',
        ),
        const AppBanner(message: 'Connected', tone: AppBannerTone.success),
        const AppBanner(
          message: "Can't reach the camera",
          tone: AppBannerTone.error,
        ),
        const AppBanner(message: 'Same Wi-Fi as the camera works best.'),
      ],
    );
  }
}

// --------------------------------------------------------------------- tiles

class _TilesSection extends StatelessWidget {
  const _TilesSection();

  Widget _tile(
    String name,
    StreamStatus status,
    String label,
    double hue, {
    bool video = true,
  }) {
    return CameraTile(
      name: name,
      status: status,
      statusLabel: label,
      resolutionLabel: '1920x1080',
      video: video ? _FakePicture(hue) : null,
      isVideoVisible: video,
      onTap: () {},
      onStatusTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: <Widget>[
        const _Note(
          'The tile at three widths: 360, 180 and 97 (the 4x4 grid on a phone).',
        ),
        SizedBox(
          width: 360,
          height: 360 * 9 / 16,
          child: _tile('Front door', StreamStatus.live, 'Live', 200),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            SizedBox(
              width: 180,
              height: 180 * 9 / 16,
              child: _tile('Garden', StreamStatus.live, 'Live', 120),
            ),
            SizedBox(
              width: 180,
              height: 180 * 9 / 16,
              child: _tile(
                'Garage',
                StreamStatus.connecting,
                'Connecting',
                30,
                video: false,
              ),
            ),
            SizedBox(
              width: 97,
              height: 97 * 9 / 16,
              child: _tile(
                'Gate',
                StreamStatus.error,
                "Can't reach",
                300,
                video: false,
              ),
            ),
            SizedBox(
              width: 97,
              height: 97 * 9 / 16,
              child: _tile(
                'Roof',
                StreamStatus.offline,
                'Offline',
                60,
                video: false,
              ),
            ),
          ],
        ),
        const _Note('2x2 grid (phone gutter), then 4x4.'),
        SizedBox(
          height: 300,
          child: CameraGrid(
            columns: 2,
            rows: 2,
            tiles: <Widget>[
              _tile('One', StreamStatus.live, 'Live', 10),
              _tile('Two', StreamStatus.live, 'Live', 90),
              _tile(
                'Three',
                StreamStatus.reconnecting,
                'Reconnecting',
                170,
                video: false,
              ),
              _tile('Four', StreamStatus.live, 'Live', 250),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: CameraGrid(
            columns: 4,
            rows: 4,
            tiles: <Widget>[
              for (int i = 0; i < 16; i++)
                _tile(
                  'Cam ${i + 1}',
                  i % 5 == 4 ? StreamStatus.error : StreamStatus.live,
                  i % 5 == 4 ? 'Error' : 'Live',
                  i * 22.0,
                ),
            ],
          ),
        ),
        _Notified<int>(
          initial: 4,
          builder: (BuildContext context, int size, ValueSetter<int> set) {
            return GridLayoutPicker(
              selected: size,
              onSelected: set,
              labelFor: (int n) => '$n',
            );
          },
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------- PTZ

class _PtzSection extends StatelessWidget {
  const _PtzSection({required this.controls});

  final _Controls controls;

  static const PtzPadLabels _labels = PtzPadLabels(
    pad: 'PTZ pad',
    home: 'Home',
    zoomIn: 'Zoom in',
    zoomOut: 'Zoom out',
  );

  @override
  Widget build(BuildContext context) {
    return _Notified<String>(
      initial: 'Drag the pad. Nothing is sent to any camera.',
      builder: (BuildContext context, String message, ValueSetter<String> set) {
        return _Page(
          children: <Widget>[
            _Note(message),
            Center(
              child: PtzPad(
                labels: _labels,
                onMove: (double pan, double tilt) => set(
                  'move pan ${pan.toStringAsFixed(1)} tilt ${tilt.toStringAsFixed(1)}',
                ),
                onStop: () => set('stop'),
                onZoom: (double z) => set('zoom $z'),
                onHome: () => set('home'),
              ),
            ),
            _Notified<double>(
              initial: 0.5,
              builder:
                  (
                    BuildContext context,
                    double speed,
                    ValueSetter<double> setSpeed,
                  ) {
                    return PtzSpeedControl(
                      value: speed,
                      onChanged: setSpeed,
                      label: 'Speed',
                    );
                  },
            ),
            AppButton(
              label: 'Open fullscreen controls',
              icon: AppIconName.fullscreenEnter,
              onPressed: () {
                Navigator.of(context).push<void>(
                  AppPageRoute<void>(
                    builder: (BuildContext _) => const _FullscreenDemo(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _FullscreenDemo extends StatelessWidget {
  const _FullscreenDemo();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      immersive: true,
      body: FullscreenControls(
        title: 'Front door',
        closeLabel: 'Close',
        onClose: () => Navigator.of(context).pop(),
        statusPill: const StreamStatusPill(
          status: StreamStatus.live,
          label: 'Live',
        ),
        topActions: <FullscreenAction>[
          FullscreenAction(
            icon: AppIconName.volumeOff,
            label: 'Mute',
            onPressed: () {},
          ),
        ],
        bottomActions: <FullscreenAction>[
          FullscreenAction(
            icon: AppIconName.snapshot,
            label: 'Snapshot',
            onPressed: () {},
          ),
          FullscreenAction(
            icon: AppIconName.cameraPtz,
            label: 'PTZ',
            selected: true,
            onPressed: () {},
          ),
        ],
        panel: const SizedBox(
          width: 176,
          child: Center(child: Text('PTZ pad goes here', maxLines: 1)),
        ),
        child: const _FakePicture(200),
      ),
    );
  }
}

// -------------------------------------------------------------------- brands

class _BrandsSection extends StatelessWidget {
  const _BrandsSection();

  static const List<String> _names = <String>[
    'Amcrest',
    'Annke',
    'Arlo',
    'Axis',
    'Bosch',
    'Dahua',
    'D-Link',
    'EZVIZ',
    'Foscam',
    'Hanwha',
    'Hikvision',
    'Imou',
    'Lorex',
    'Mobotix',
    'Reolink',
    'Samsung',
    'Sony',
    'Swann',
    'TP-Link',
    'Tapo',
    'Uniview',
    'Vivotek',
    'Wyze',
    'Xiaomi',
    'Yi',
    'Zosi',
    '4K Generic',
  ];

  @override
  Widget build(BuildContext context) {
    final List<CameraBrandProfile> brands = <CameraBrandProfile>[
      for (final String name in _names)
        CameraBrandProfile(
          id: name.toLowerCase(),
          displayName: name,
          defaultPorts: const <int>[554],
          mainPathTemplates: const <String>['/'],
          subPathTemplates: const <String>[],
          mjpegTemplates: const <String>[],
          snapshotTemplates: const <String>[],
          verified: name == 'Hikvision' || name == 'Reolink' || name == 'Axis',
        ),
    ];
    return BrandPicker(
      brands: brands,
      searchLabel: 'Search brands',
      noResultsTitle: 'No brand found',
      noResultsMessage: 'Try another name, or choose Generic.',
      verifiedLabel: 'Verified',
      onSelected: (CameraBrandProfile brand) {
        AppToast.show(
          context,
          message: '${brand.displayName} chosen',
          icon: AppIconName.check,
        );
      },
    );
  }
}

// ------------------------------------------------------------------ overlays

class _OverlaysSection extends StatelessWidget {
  const _OverlaysSection({required this.controls});

  final _Controls controls;

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: <Widget>[
        const _Note(
          'The ad slot sits above the bottom bar: it grows over 200 ms and collapses to nothing. Tap a field in Components to see the bars collapse under the keyboard.',
        ),
        ValueListenableBuilder<AdSlotState>(
          valueListenable: controls.ad,
          builder: (BuildContext context, AdSlotState state, Widget? _) {
            return AppButton(
              label: state.isVisible
                  ? 'Remove the ad slot'
                  : 'Show the ad slot',
              kind: AppButtonKind.secondary,
              icon: AppIconName.upgrade,
              expand: true,
              onPressed: () {
                controls.ad.value = state.isVisible
                    ? AdSlotState.collapsed
                    : AdSlotState(height: 60, view: Object());
              },
            );
          },
        ),
        AppButton(
          label: 'Toast with Undo',
          kind: AppButtonKind.tinted,
          expand: true,
          onPressed: () {
            AppToast.show(
              context,
              message: 'Camera deleted',
              actionLabel: 'Undo',
              onAction: () {},
              duration: const Duration(seconds: 8),
            );
          },
        ),
        AppButton(
          label: 'Bottom sheet',
          kind: AppButtonKind.tinted,
          expand: true,
          onPressed: () {
            showAppSheet<void>(
              context,
              dismissLabel: 'Close',
              title: 'Layout',
              builder: (BuildContext _) =>
                  const Padding(padding: AppSpacing.allMd, child: _SheetBody()),
            );
          },
        ),
        AppButton(
          label: 'Dialog',
          kind: AppButtonKind.tinted,
          expand: true,
          onPressed: () {
            showAppDialog<void>(
              context,
              dismissLabel: 'Cancel',
              builder: (BuildContext dialogContext) => AppDialog(
                title: 'Delete this camera?',
                message: 'It will be removed from this phone. Its password is erased too.',
                actions: <AppDialogAction>[
                  AppDialogAction(
                    label: 'Delete',
                    kind: AppButtonKind.destructive,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                  AppDialogAction(
                    label: 'Keep',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  @override
  Widget build(BuildContext context) {
    return _Notified<int>(
      initial: 4,
      builder: (BuildContext context, int size, ValueSetter<int> set) {
        return GridLayoutPicker(
          selected: size,
          onSelected: set,
          labelFor: (int n) => '$n',
        );
      },
    );
  }
}

// -------------------------------------------------------------------- Arabic

class _ArabicSection extends StatelessWidget {
  const _ArabicSection();

  @override
  Widget build(BuildContext context) {
    final TextEditingController address = TextEditingController(
      text: 'rtsp://192.168.1.20:554/stream1',
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _Page(
        children: <Widget>[
          const _Note(
            'هذا القسم يعرض الواجهة من اليمين إلى اليسار دائمًا. العناوين تبقى من اليسار إلى اليمين.',
          ),
          const AppNavBar(title: 'الإعدادات', actions: <Widget>[]),
          AppSection(
            title: 'عام',
            children: <Widget>[
              AppListRow(
                leading: AppIconName.moon,
                title: 'المظهر',
                subtitle: 'داكن',
                onTap: () {},
              ),
              AppListRow(
                leading: AppIconName.globe,
                title: 'اللغة',
                subtitle: 'العربية',
                onTap: () {},
              ),
              AppListRow(
                leading: AppIconName.help,
                title: 'المساعدة',
                onTap: () {},
              ),
            ],
          ),
          AppTextField(
            controller: address,
            label: 'عنوان الكاميرا',
            forceLtr: true,
            monospace: true,
          ),
          Row(
            children: <Widget>[
              AppChip(
                label: 'إعادة المحاولة',
                icon: AppIconName.refresh,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              AppChip(label: 'تعديل', icon: AppIconName.edit, onTap: () {}),
            ],
          ),
          const AppBanner(
            message: 'تعذر الوصول إلى الكاميرا',
            tone: AppBannerTone.error,
            actionLabel: 'إعادة',
          ),
        ],
      ),
    );
  }
}
