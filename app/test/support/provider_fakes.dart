import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roehens/core/contracts/ad_contract.dart';
import 'package:roehens/core/contracts/consent_contract.dart';
import 'package:roehens/core/contracts/discovery_contract.dart';
import 'package:roehens/core/contracts/flags_contract.dart';
import 'package:roehens/core/contracts/permission_contract.dart';
import 'package:roehens/core/contracts/purchase_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/entitlement.dart';
import 'package:roehens/core/models/remote_flags.dart';

class FakePurchase implements PurchaseContract {
  FakePurchase({this.supported = true});

  final bool supported;
  Entitlement current = const Entitlement.free();
  bool failCurrent = false;
  AppError? buyError;
  int buyCalls = 0;
  int restoreCalls = 0;
  ProductInfo? product = const ProductInfo(
    id: 'p',
    title: 'Ad-free',
    priceLabel: r'$2.99',
  );

  final StreamController<Entitlement> changes =
      StreamController<Entitlement>.broadcast();
  final StreamController<AppError> failureController =
      StreamController<AppError>.broadcast();

  @override
  bool get isSupported => supported;

  @override
  Stream<Entitlement> get entitlementChanges => changes.stream;

  @override
  Stream<AppError> get failures => failureController.stream;

  @override
  Future<Result<Entitlement>> currentEntitlement() async {
    if (failCurrent) {
      return const Err<Entitlement>(AppError(ErrorClass.purchaseFailed));
    }
    return Ok<Entitlement>(current);
  }

  @override
  Future<Result<ProductInfo?>> loadProduct() async => Ok<ProductInfo?>(product);

  @override
  Future<Result<void>> buy() async {
    buyCalls++;
    final AppError? error = buyError;
    return error == null ? const Ok<void>(null) : Err<void>(error);
  }

  @override
  Future<Result<void>> restore() async {
    restoreCalls++;
    return const Ok<void>(null);
  }
}

class FakeFlags implements FlagsContract {
  final ValueNotifier<RemoteFlags> notifier =
      ValueNotifier<RemoteFlags>(RemoteFlags.defaults);
  int refreshCalls = 0;

  @override
  ValueListenable<RemoteFlags> get flags => notifier;

  @override
  Future<void> refresh() async => refreshCalls++;
}

class FakeDiscovery implements DiscoveryContract {
  final StreamController<DiscoveryEvent> controller =
      StreamController<DiscoveryEvent>();
  int runs = 0;

  @override
  Stream<DiscoveryEvent> discover({required Duration timeout}) {
    runs++;
    return controller.stream;
  }
}

class FakePermission implements PermissionContract {
  FakePermission(this.status, {this.afterRequest});

  PermissionStatus status;
  PermissionStatus? afterRequest;
  int requests = 0;

  @override
  Future<PermissionStatus> localNetworkStatus() async => status;

  @override
  Future<PermissionStatus> requestLocalNetwork() async {
    requests++;
    status = afterRequest ?? status;
    return status;
  }

  @override
  Future<bool> openAppSettings() async => true;
}

class FakeAd implements AdContract {
  final ValueNotifier<double> height = ValueNotifier<double>(0);
  Object? view;
  int initializeCalls = 0;
  int disposeCalls = 0;
  final List<int> loadedWidths = <int>[];

  /// Height and view a successful load produces.
  double nextHeight = 60;

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  ValueListenable<double> get bannerHeight => height;

  @override
  Future<void> loadBanner({required int widthDp}) async {
    loadedWidths.add(widthDp);
    view = Object();
    height.value = nextHeight;
  }

  @override
  Object? get bannerView => view;

  @override
  void disposeBanner() {
    disposeCalls++;
    view = null;
    height.value = 0;
  }
}

class FakeConsent implements ConsentContract {
  FakeConsent({this.canRequest = true});

  bool canRequest;
  int gatherCalls = 0;
  bool throwOnGather = false;

  @override
  ConsentStatus get status =>
      canRequest ? ConsentStatus.obtained : ConsentStatus.unknown;

  @override
  bool get canRequestAds => canRequest;

  @override
  Future<ConsentStatus> gatherConsent() async {
    gatherCalls++;
    if (throwOnGather) {
      throw StateError('consent form crashed');
    }
    return status;
  }

  @override
  Future<bool> get privacyOptionsRequired async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}
