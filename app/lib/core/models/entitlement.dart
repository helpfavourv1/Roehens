/// What the person has: the free app with ads, or the ad-free unlock.
enum EntitlementTier { free, adFree }

/// Where the entitlement was established.
enum EntitlementSource { none, purchase, restore, cache }

class Entitlement {
  const Entitlement({
    required this.tier,
    required this.source,
    this.verifiedAt,
  });

  const Entitlement.free()
      : tier = EntitlementTier.free,
        source = EntitlementSource.none,
        verifiedAt = null;

  factory Entitlement.fromJson(Map<String, Object?> json) {
    final int? verified = json['verifiedAtMillis'] as int?;
    return Entitlement(
      tier: EntitlementTier.values.byName(json['tier']! as String),
      source: EntitlementSource.values.byName(json['source']! as String),
      verifiedAt: verified == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(verified, isUtc: true),
    );
  }

  final EntitlementTier tier;
  final EntitlementSource source;
  final DateTime? verifiedAt;

  bool get isAdFree => tier == EntitlementTier.adFree;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'tier': tier.name,
      'source': source.name,
      'verifiedAtMillis': verifiedAt?.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is Entitlement &&
        other.tier == tier &&
        other.source == source &&
        other.verifiedAt == verifiedAt;
  }

  @override
  int get hashCode => Object.hash(tier, source, verifiedAt);
}
