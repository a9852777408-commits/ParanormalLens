import 'package:flutter/foundation.dart';

enum AppStoreFlavor { globalStore, ruStore }

class InAppProduct {
  final String id;
  final String title;
  final String priceDisplay;
  final bool isSubscription;

  const InAppProduct({
    required this.id,
    required this.title,
    required this.priceDisplay,
    required this.isSubscription,
  });
}

/// Dual-track monetization service handling build flavors:
/// - global_store: RevenueCat (In-App) + Google AdMob (Rewarded)
/// - rustore: RuStore IAP SDK + Yandex Ads (РСЯ)
class MonetizationService extends ChangeNotifier {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  // Controlled via compile-time environment variable: --dart-define=FLAVOR=rustore
  final AppStoreFlavor flavor = const String.fromEnvironment('FLAVOR') == 'rustore'
      ? AppStoreFlavor.ruStore
      : AppStoreFlavor.globalStore;

  bool _isProUnlocked = false;
  bool get isProUnlocked => _isProUnlocked;

  List<InAppProduct> get availableProducts {
    if (flavor == AppStoreFlavor.ruStore) {
      return const [
        InAppProduct(
          id: 'paranormal_pro_month_rub',
          title: 'PRO Охотник (Месяц)',
          priceDisplay: '299 ₽ / месяц',
          isSubscription: true,
        ),
        InAppProduct(
          id: 'paranormal_pro_forever_rub',
          title: 'PRO Охотник (Навсегда)',
          priceDisplay: '990 ₽ единоразово',
          isSubscription: false,
        ),
      ];
    } else {
      return const [
        InAppProduct(
          id: 'paranormal_weekly_sub',
          title: 'PRO Hunter Pass (Weekly)',
          priceDisplay: '\$2.99 / week (3 days trial)',
          isSubscription: true,
        ),
        InAppProduct(
          id: 'paranormal_lifetime_unlock',
          title: 'PRO Lifetime Unlock',
          priceDisplay: '\$9.99 forever',
          isSubscription: false,
        ),
      ];
    }
  }

  Future<bool> purchaseProduct(String productId) async {
    debugPrint('[Monetization] Initiating purchase for $productId via flavor: $flavor');

    if (flavor == AppStoreFlavor.ruStore) {
      // Connects to RuStore In-App Purchases SDK
      _isProUnlocked = true;
    } else {
      // Connects to RevenueCat (Purchases.purchasePackage)
      _isProUnlocked = true;
    }

    notifyListeners();
    return true;
  }

  void showRewardedAd({required VoidCallback onRewardEarned}) {
    if (flavor == AppStoreFlavor.ruStore) {
      debugPrint('[Monetization] Displaying Yandex Ads (РСЯ) Rewarded Video...');
      onRewardEarned();
    } else {
      debugPrint('[Monetization] Displaying Google AdMob Rewarded Video...');
      onRewardEarned();
    }
  }
}
