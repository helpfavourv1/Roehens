import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/ui/components/app_icon_button.dart';
import 'package:roehens/ui/components/app_selection_controls.dart';
import 'package:roehens/ui/components/app_text_selection_toolbar.dart';
import 'package:roehens/ui/icons/app_icon.dart';
import 'package:roehens/ui/icons/app_icons.dart';
import 'package:roehens/ui/tokens/color_tokens.dart';
import 'package:roehens/ui/tokens/motion_tokens.dart';
import 'package:roehens/ui/tokens/radius_tokens.dart';
import 'package:roehens/ui/tokens/size_tokens.dart';
import 'package:roehens/ui/tokens/spacing_tokens.dart';
import 'package:roehens/utils/context_extensions.dart';

/// The one text input: a label above, a filled field, and a helper or error
/// line below. [forceLtr] keeps IPs, ports, URLs and paths left-to-right inside
/// right-to-left layouts; [monospace] sets the mono face for the same values.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.leadingIcon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.revealLabel,
    this.concealLabel,
    this.enabled = true,
    this.autofocus = false,
    this.forceLtr = false,
    this.monospace = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
  }) : assert(
         !obscureText || (revealLabel != null && concealLabel != null),
         'A password field needs labels for its show/hide button.',
       );

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;

  /// A non-null value shows the field in its error state with this message.
  final String? errorText;
  final AppIconName? leadingIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// Hides the text and adds a show/hide button.
  final bool obscureText;
  final String? revealLabel;
  final String? concealLabel;
  final bool enabled;
  final bool autofocus;
  final bool forceLtr;
  final bool monospace;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  static final AppSelectionControls _selectionControls = AppSelectionControls();

  // A bare EditableText does not react to taps or long presses. The gesture
  // builder is what places the caret, selects a word on a long press, shows the
  // handles and opens the cut/copy/paste bar; stock text fields get it from
  // their own wrapper.
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  FocusNode? _ownedFocus;
  final ValueNotifier<bool> _focused = ValueNotifier<bool>(false);
  late final ValueNotifier<bool> _concealed = ValueNotifier<bool>(
    widget.obscureText,
  );

  FocusNode get _focusNode => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocus)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownedFocus?.dispose();
    _focused.dispose();
    _concealed.dispose();
    super.dispose();
  }

  void _onFocusChanged() => _focused.value = _focusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool hasError = widget.errorText != null;
    final TextStyle base = widget.monospace
        ? context.type.mono
        : context.type.body;
    final TextStyle style = base.copyWith(
      color: widget.enabled ? colors.textPrimary : colors.textTertiary,
    );
    final TextDirection? direction = widget.forceLtr ? TextDirection.ltr : null;

    final Widget input = ValueListenableBuilder<bool>(
      valueListenable: _concealed,
      builder: (BuildContext context, bool concealed, Widget? _) {
        return Stack(
          alignment: AlignmentDirectional.centerStart,
          children: <Widget>[
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder:
                  (BuildContext context, TextEditingValue value, Widget? _) {
                    if (value.text.isNotEmpty || widget.hint == null) {
                      return const SizedBox.shrink();
                    }
                    return IgnorePointer(
                      child: Text(
                        widget.hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: direction,
                        style: style.copyWith(color: colors.textTertiary),
                      ),
                    );
                  },
            ),
            _gestures.buildGestureDetector(
              behavior: HitTestBehavior.translucent,
              child: EditableText(
              key: editableTextKey,
              rendererIgnoresPointer: true,
              controller: widget.controller,
              focusNode: _focusNode,
              style: style,
              cursorColor: colors.accent,
              backgroundCursorColor: colors.bgTertiary,
              selectionColor: colors.accentWash,
              selectionControls: _selectionControls,
              contextMenuBuilder: AppTextSelectionToolbar.builder,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              obscureText: concealed,
              autocorrect: false,
              enableSuggestions: !widget.obscureText && !widget.forceLtr,
              readOnly: !widget.enabled,
              autofocus: widget.autofocus,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              textDirection: direction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
            ),
          ],
        );
      },
    );

    final Widget field = ValueListenableBuilder<bool>(
      valueListenable: _focused,
      builder: (BuildContext context, bool focused, Widget? child) {
        final Color border = hasError
            ? colors.error
            : focused
            ? colors.borderFocus
            : colors.borderStrong;
        return AnimatedContainer(
          duration: context.motion(AppMotion.press),
          curve: AppMotion.settle,
          decoration: BoxDecoration(
            color: colors.bgTertiary,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: border, width: AppSizes.inputBorder),
          ),
          child: child,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.enabled ? _focusNode.requestFocus : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.buttonMinHeight,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.xs,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                if (widget.leadingIcon != null) ...<Widget>[
                  AppIcon(
                    widget.leadingIcon!,
                    size: AppSizes.iconRowTrailing,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(child: input),
                if (widget.obscureText)
                  ValueListenableBuilder<bool>(
                    valueListenable: _concealed,
                    builder: (BuildContext context, bool concealed, Widget? _) {
                      return AppIconButton(
                        icon: concealed ? AppIconName.show : AppIconName.hide,
                        semanticLabel: concealed
                            ? widget.revealLabel!
                            : widget.concealLabel!,
                        onPressed: () => _concealed.value = !concealed,
                      );
                    },
                  )
                else
                  const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );

    final String? message = widget.errorText ?? widget.helperText;
    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      textField: true,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.label != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: Text(
                widget.label!,
                style: context.type.callout.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          field,
          if (message != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (hasError) ...<Widget>[
                    AppIcon(
                      AppIconName.warning,
                      size: AppSizes.iconChipGlyph,
                      color: colors.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      message,
                      style: context.type.footnote.copyWith(
                        color: hasError ? colors.error : colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
