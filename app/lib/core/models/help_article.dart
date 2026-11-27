/// A value a person may copy from a Help step, such as a port. Shown in the
/// Mono face, always left-to-right.
class HelpCopyValue {
  const HelpCopyValue({required this.id, required this.value});

  final String id;
  final String value;

  @override
  bool operator ==(Object other) {
    return other is HelpCopyValue && other.id == id && other.value == value;
  }

  @override
  int get hashCode => Object.hash(id, value);
}

/// Where a Help step can take the person. Only places inside Roehens or the
/// phone's own Settings: Help has no outbound web links.
enum HelpTargetKind {
  addCamera,
  findCameras,
  diagnostics,
  troubleshooter,
  phoneSettings,
  article,
}

class HelpTarget {
  const HelpTarget(this.kind, [this.articleId]);

  /// Reads the target ids used in `help_structure.json`:
  /// `add_camera`, `find_cameras`, `diagnostics`, `troubleshooter`,
  /// `phone_settings`, or `article:<id>`. Null for anything else.
  static HelpTarget? parse(String? text) {
    if (text == null) {
      return null;
    }
    if (text.startsWith('article:') && text.length > 'article:'.length) {
      return HelpTarget(HelpTargetKind.article, text.substring(8));
    }
    return switch (text) {
      'add_camera' => const HelpTarget(HelpTargetKind.addCamera),
      'find_cameras' => const HelpTarget(HelpTargetKind.findCameras),
      'diagnostics' => const HelpTarget(HelpTargetKind.diagnostics),
      'troubleshooter' => const HelpTarget(HelpTargetKind.troubleshooter),
      'phone_settings' => const HelpTarget(HelpTargetKind.phoneSettings),
      _ => null,
    };
  }

  final HelpTargetKind kind;

  /// The article opened, for [HelpTargetKind.article].
  final String? articleId;

  @override
  bool operator ==(Object other) {
    return other is HelpTarget &&
        other.kind == kind &&
        other.articleId == articleId;
  }

  @override
  int get hashCode => Object.hash(kind, articleId);
}

/// One step of an article. Its visible text lives in the language files under
/// keys the catalog derives from the ids.
class HelpStep {
  const HelpStep({
    required this.id,
    this.copyValues = const <HelpCopyValue>[],
    this.hasCallout = false,
    this.target,
  });

  final String id;
  final List<HelpCopyValue> copyValues;
  final bool hasCallout;
  final HelpTarget? target;
}

/// Where an article belongs on the hub.
enum HelpGroup { sameWifi, away }

class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.group,
    required this.steps,
  });

  final String id;
  final HelpGroup group;
  final List<HelpStep> steps;
}
