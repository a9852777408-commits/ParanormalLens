import 'package:flutter/material.dart';
import '../../core/models/regional_profile.dart';
import '../../core/services/geo_adaptation_service.dart';

class AnomalyCardModel {
  final String id;
  final String name;
  final String rarity;
  final String location;
  final String timestamp;
  final String lore;
  final bool isCaptured;

  const AnomalyCardModel({
    required this.id,
    required this.name,
    required this.rarity,
    required this.location,
    required this.timestamp,
    required this.lore,
    this.isCaptured = false,
  });
}

/// In-game Bestiary / Paranormal Archive Screen:
/// Pokemon GO style collection gallery with evidence dossiers and viral sharing.
class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  int _selectedFilterTab = 0; // 0: All, 1: Captured, 2: Legendary

  // Seed collection records matching the app's lore
  final List<AnomalyCardModel> _anomalies = const [
    AnomalyCardModel(
      id: 'paul_first',
      name: 'Призрак Павла I',
      rarity: 'Legendary',
      location: 'Михайловский замок, СПб',
      timestamp: '02:41 AM (59.94° N, 30.33° E)',
      lore: 'Убитый заговорщиками император со свечой в руках бродит по темным залам замка и играет на флажолете.',
      isCaptured: true,
    ),
    AnomalyCardModel(
      id: 'inverted_raven',
      name: 'Инвертированный Ворон',
      rarity: 'Rare',
      location: 'Оконная рама / Чердак',
      timestamp: '01:15 AM',
      lore: 'Сидит на раме окна вверх ногами и улетает вниз в бездну, нарушая законы гравитации.',
      isCaptured: true,
    ),
    AnomalyCardModel(
      id: 'white_cemetery_watcher',
      name: 'Белый Кладбищенский Страж',
      rarity: 'Mythic',
      location: 'Старое Кладбище / Некрополь',
      timestamp: '03:10 AM',
      lore: 'Молочно-белый полупрозрачный силуэт, застывший в абсолютной неподвижности среди крестов.',
      isCaptured: true,
    ),
    AnomalyCardModel(
      id: 'flying_head_phantom',
      name: 'Летающий Морок (Голова)',
      rarity: 'Uncommon',
      location: 'Жилая комната / Потолок',
      timestamp: '00:48 AM',
      lore: 'Парящая под потолком отрубленная тень с длинным шлейфом клубящегося черного дыма.',
      isCaptured: true,
    ),
    AnomalyCardModel(
      id: 'domestic_poltergeist',
      name: 'Барабашка (Полтергейст)',
      rarity: 'Common',
      location: 'Домашняя аномалия',
      timestamp: '23:35 PM',
      lore: 'Низкорослый сгорбленный силуэт у плинтуса, вызывающий треск магнитометра и стук предметов.',
      isCaptured: true,
    ),
    AnomalyCardModel(
      id: 'jacob_bruce',
      name: 'Чернокнижник Яков Брюс',
      rarity: 'Legendary',
      location: 'Сухаревская площадь, Москва',
      timestamp: 'Не обнаружен',
      lore: 'Алхимик и чернокнижник петровской эпохи, ищущий свою тайную книгу в фундаменте разрушенной башни.',
      isCaptured: false,
    ),
    AnomalyCardModel(
      id: 'ostankino_prophetess',
      name: 'Вещая старуха Останкино',
      rarity: 'Legendary',
      location: 'Останкинская усадьба, Москва',
      timestamp: 'Не обнаружен',
      lore: 'Сгорбленная старуха с клюкой, являющаяся перед крупными пожарами и бедами.',
      isCaptured: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = GeoAdaptationService().activeProfile;
    final capturedCount = _anomalies.where((a) => a.isCaptured).length;

    List<AnomalyCardModel> displayedList = _anomalies;
    if (_selectedFilterTab == 1) {
      displayedList = _anomalies.where((a) => a.isCaptured).toList();
    } else if (_selectedFilterTab == 2) {
      displayedList = _anomalies.where((a) => a.rarity == 'Legendary' || a.rarity == 'Mythic').toList();
    }

    return Scaffold(
      backgroundColor: profile.aesthetic.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'АРХИВ ЭКЗОРЦИСТА',
          style: TextStyle(
            color: profile.aesthetic.accent,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: profile.aesthetic.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: profile.aesthetic.accent.withOpacity(0.5)),
                ),
                child: Text(
                  'ПОЙМАНО: $capturedCount / ${_anomalies.length}',
                  style: TextStyle(
                    color: profile.aesthetic.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildTabButton('Все (${_anomalies.length})', 0, profile),
                const SizedBox(width: 8),
                _buildTabButton('Пойманные ($capturedCount)', 1, profile),
                const SizedBox(width: 8),
                _buildTabButton('Легенды', 2, profile),
              ],
            ),
          ),

          // Cards Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              itemCount: displayedList.length,
              itemBuilder: (context, index) {
                final item = displayedList[index];
                return _buildAnomalyCard(item, profile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, RegionalProfile profile) {
    final isSelected = _selectedFilterTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? profile.aesthetic.accent : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? profile.aesthetic.accent : Colors.white12,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyCardModel item, RegionalProfile profile) {
    return GestureDetector(
      onTap: () => _showDetailModal(item, profile),
      child: Container(
        decoration: BoxDecoration(
          color: item.isCaptured
              ? profile.aesthetic.primary.withOpacity(0.7)
              : Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isCaptured
                ? profile.aesthetic.accent.withOpacity(0.6)
                : Colors.white12,
            width: item.isCaptured ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rarity Badge & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRarityColor(item.rarity).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getRarityColor(item.rarity), width: 0.8),
                  ),
                  child: Text(
                    item.rarity.toUpperCase(),
                    style: TextStyle(
                      color: _getRarityColor(item.rarity),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  item.isCaptured ? Icons.check_circle : Icons.lock_outline,
                  color: item.isCaptured ? profile.aesthetic.accent : Colors.white30,
                  size: 16,
                ),
              ],
            ),

            const Spacer(),

            // Ghost Visual Icon
            Center(
              child: Icon(
                item.isCaptured ? Icons.lens_blur : Icons.help_outline,
                color: item.isCaptured ? profile.aesthetic.accent : Colors.white24,
                size: 52,
              ),
            ),

            const Spacer(),

            // Title & Location
            Text(
              item.isCaptured ? item.name : '??? Неизвестно',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.isCaptured ? item.location : 'Исследуйте карту',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.isCaptured ? profile.aesthetic.accent : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'mythic':
        return Colors.purpleAccent;
      case 'legendary':
        return Colors.amber;
      case 'rare':
        return Colors.lightBlueAccent;
      case 'uncommon':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  void _showDetailModal(AnomalyCardModel item, RegionalProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: profile.aesthetic.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.isCaptured ? item.name : 'Нераскрытая аномалия',
                    style: TextStyle(
                      color: profile.aesthetic.accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '📍 ${item.location} • 🕒 ${item.timestamp}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: profile.aesthetic.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: profile.aesthetic.accent.withOpacity(0.3)),
                ),
                child: Text(
                  item.lore,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              if (item.isCaptured)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: profile.aesthetic.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('📸 Карточка "${item.name}" подготовлена для шеринга в соцсети!')),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text(
                      'ПОДЕЛИТЬСЯ В СОЦСЕТЯХ (TIKTOK / TELEGRAM)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
