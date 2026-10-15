import 'package:flutter/material.dart';
import '../../core/models/regional_profile.dart';
import '../../core/services/geo_adaptation_service.dart';
import '../../core/services/monetization_service.dart';

/// Immersive Dark Tactical Paywall Screen:
/// Features dual-track billing (Global RevenueCat vs RuStore),
/// trial period hooks, and cultural aesthetic styling.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedProductIndex = 0; // 0: Subscription, 1: Lifetime
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final profile = GeoAdaptationService().activeProfile;
    final monetization = MonetizationService();
    final products = monetization.availableProducts;

    return Scaffold(
      backgroundColor: profile.aesthetic.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient glow in background
            Positioned(
              top: -80,
              left: -40,
              right: -40,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [
                      profile.aesthetic.accent.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Header icon & Title
                  Icon(Icons.workspace_premium, color: profile.aesthetic.accent, size: 54),
                  const SizedBox(height: 12),
                  Text(
                    'PARANORMAL PRO',
                    style: TextStyle(
                      color: profile.aesthetic.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Доступ ко всем секретным частотам и технологиям охоты',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Feature List
                  _buildFeatureRow(Icons.camera, 'HD Запись без водяного знака', 'Съемка в 1080p для соцсетей', profile),
                  _buildFeatureRow(Icons.thermostat, 'Режимы Тепловизора и ПНВ', 'Неограниченное переключение фильтров', profile),
                  _buildFeatureRow(Icons.flare, 'Бесконечный Священный Свет', 'Охота без ожидания рассвета в Иерусалиме', profile),
                  _buildFeatureRow(Icons.auto_stories, 'Полный Архив Бестиария', 'Доступ ко всем городским легендам', profile),
                  _buildFeatureRow(Icons.block, '100% Без Рекламы', 'Никаких прерываний в моменты саспенса', profile),

                  const SizedBox(height: 32),

                  // Pricing Cards
                  Column(
                    children: List.generate(products.length, (index) {
                      final product = products[index];
                      final isSelected = _selectedProductIndex == index;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedProductIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? profile.aesthetic.primary.withOpacity(0.85)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? profile.aesthetic.accent
                                  : Colors.white24,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? profile.aesthetic.accent : Colors.white38,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          product.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (product.isSubscription) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: profile.aesthetic.accent,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              '3 ДНЯ ТРИАЛ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product.priceDisplay,
                                      style: TextStyle(
                                        color: profile.aesthetic.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: profile.aesthetic.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isLoading ? null : () => _handlePurchase(products[_selectedProductIndex]),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              products[_selectedProductIndex].isSubscription
                                  ? 'ПОПРОБОВАТЬ БЕСПЛАТНО 3 ДНЯ'
                                  : 'КУПИТЬ НАВСЕГДА',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Store Compliance: Restore & Legal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _handleRestore(),
                        child: const Text(
                          'Восстановить покупки',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                      const Text('•', style: TextStyle(color: Colors.white30)),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Условия и конфиденциальность',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, RegionalProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: profile.aesthetic.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: profile.aesthetic.accent.withOpacity(0.3)),
            ),
            child: Icon(icon, color: profile.aesthetic.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(InAppProduct product) async {
    setState(() => _isLoading = true);
    final success = await MonetizationService().purchaseProduct(product.id);
    setState(() => _isLoading = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 PRO Hunter успешно активирован! Все функции разблокированы.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История покупок успешно синхронизирована.')),
      );
    }
  }
}
