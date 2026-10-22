import 'package:flutter/material.dart';
import '../../core/models/regional_profile.dart';
import '../../core/services/geo_adaptation_service.dart';
import '../../core/services/audio_service.dart';

class AnomalyCardModel {
  final String id;
  final String name;
  final String rarity;
  final String location;
  final String timestamp;
  final String lore;
  final String weakness;
  final double emfLevel;
  final int dangerLevel; // 1 to 5
  final IconData icon;
  final Color glowColor;

  const AnomalyCardModel({
    required this.id,
    required this.name,
    required this.rarity,
    required this.location,
    required this.timestamp,
    required this.lore,
    required this.weakness,
    required this.emfLevel,
    required this.dangerLevel,
    required this.icon,
    required this.glowColor,
  });
}

/// In-game Bestiary / Paranormal Archive Screen:
/// Fully unlocked in test mode with 8 detailed entity dossiers & EVP audio playback
class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  int _selectedFilterTab = 0; // 0: All, 1: High Threat, 2: Legendary

  final List<AnomalyCardModel> _anomalies = const [
    AnomalyCardModel(
      id: 'paul_first',
      name: 'Призрак Павла I',
      rarity: 'Legendary',
      location: 'Михайловский замок, СПб',
      timestamp: '02:41 AM (59.94° N, 30.33° E)',
      lore: 'Убитый заговорщиками император со свечой в руках бродит по темным залам замка и играет на флажолете.',
      weakness: 'Освященная свеча и молитва за упокой души.',
      emfLevel: 14.2,
      dangerLevel: 4,
      icon: Icons.person_outline,
      glowColor: Color(0xFFFFB703),
    ),
    AnomalyCardModel(
      id: 'inverted_raven',
      name: 'Инвертированный Ворон',
      rarity: 'Rare',
      location: 'Оконная рама / Чердак',
      timestamp: '01:15 AM (Вверх ногами)',
      lore: 'Сидит на раме окна вверх ногами и улетает вниз в бездну, искажая гравитацию и преломляя свет.',
      weakness: 'Крестное знамение на оконном стекле, звон колокольчика.',
      emfLevel: 8.7,
      dangerLevel: 3,
      icon: Icons.flutter_dash,
      glowColor: Color(0xFF00B4D8),
    ),
    AnomalyCardModel(
      id: 'white_cemetery_watcher',
      name: 'Белый Кладбищенский Страж',
      rarity: 'Mythic',
      location: 'Старый Некрополь / Могилы',
      timestamp: '03:10 AM (Час волка)',
      lore: 'Молочно-белый полупрозрачный силуэт, застывший в абсолютной неподвижности среди крестов.',
      weakness: 'Ладан, святая вода, отступление спиной вперед.',
      emfLevel: 19.5,
      dangerLevel: 5,
      icon: Icons.accessibility_new,
      glowColor: Color(0xFFE0AAFF),
    ),
    AnomalyCardModel(
      id: 'flying_head_phantom',
      name: 'Летающий Морок (Голова)',
      rarity: 'Uncommon',
      location: 'Жилая комната / Под потолком',
      timestamp: '00:48 AM',
      lore: 'Парящая под потолком отрубленная тень с длинным шлейфом клубящегося черного дыма.',
      weakness: 'Свет натриевой лампы, окропление полынью.',
      emfLevel: 6.4,
      dangerLevel: 2,
      icon: Icons.face,
      glowColor: Color(0xFF52B788),
    ),
    AnomalyCardModel(
      id: 'domestic_poltergeist',
      name: 'Барабашка (Полтергейст)',
      rarity: 'Common',
      location: 'Домашняя аномалия / Плинтус',
      timestamp: '23:35 PM',
      lore: 'Низкорослый сгорбленный силуэт у плинтуса, вызывающий треск датчика Гейгера и вибрацию пола.',
      weakness: 'Угощение домового на блюдце, четверговая соль.',
      emfLevel: 4.8,
      dangerLevel: 1,
      icon: Icons.pest_control_rodent,
      glowColor: Color(0xFFFB8500),
    ),
    AnomalyCardModel(
      id: 'jacob_bruce',
      name: 'Чернокнижник Яков Брюс',
      rarity: 'Legendary',
      location: 'Сухаревская площадь, Москва',
      timestamp: '01:50 AM',
      lore: 'Алхимик и астролог петровской эпохи, ищущий свою тайную книгу в фундаменте разрушенной башни.',
      weakness: 'Серебряный крест, зеркальный щит.',
      emfLevel: 16.8,
      dangerLevel: 4,
      icon: Icons.auto_stories,
      glowColor: Color(0xFF9D4EDD),
    ),
    AnomalyCardModel(
      id: 'ostankino_prophetess',
      name: 'Вещая старуха Останкино',
      rarity: 'Legendary',
      location: 'Останкинская усадьба, Москва',
      timestamp: 'Полночь перед грозой',
      lore: 'Сгорбленная старуха с клюкой, являющаяся перед крупными пожарами и предупреждающая об опасности.',
      weakness: 'Поклон до земли, молчание при встрече.',
      emfLevel: 13.1,
      dangerLevel: 4,
      icon: Icons.elderly,
      glowColor: Color(0xFFFF5400),
    ),
    AnomalyCardModel(
      id: 'banshee_evp_screamer',
      name: 'Крикливая Тень (Банши)',
      rarity: 'Mythic',
      location: 'Радиопомехи / Эфир 50Гц',
      timestamp: '03:33 AM',
      lore: 'Бесформенный сгусток высокочастотного крика, перегружающий микрофоны и искажающий оптику камеры.',
      weakness: 'Громкий колокольный звон, священное освящение.',
      emfLevel: 21.0,
      dangerLevel: 5,
      icon: Icons.record_voice_over,
      glowColor: Color(0xFFFF0054),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = GeoAdaptationService().activeProfile;

    List<AnomalyCardModel> displayedList = _anomalies;
    if (_selectedFilterTab == 1) {
      displayedList = _anomalies.where((a) => a.dangerLevel >= 4).toList();
    } else if (_selectedFilterTab == 2) {
      displayedList = _anomalies.where((a) => a.rarity == 'Legendary' || a.rarity == 'Mythic').toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'БЕСТИАРИЙ АНОМАЛИЙ',
              style: TextStyle(
                color: profile.aesthetic.accent,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'ДОСТУП ЭКЗОРЦИСТА • ВСЕ 8 СУЩНОСТЕЙ ОТКРЫТЫ',
              style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1.0),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                _buildTabButton('Все (${_anomalies.length})', 0, profile),
                const SizedBox(width: 8),
                _buildTabButton('Опасные (💀 4-5)', 1, profile),
                const SizedBox(width: 8),
                _buildTabButton('Легендарные', 2, profile),
              ],
            ),
          ),

          // Cards Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.74,
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
            color: isSelected ? profile.aesthetic.accent : const Color(0xFF14241B),
            borderRadius: BorderRadius.circular(8),
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
          color: const Color(0xFF121E17),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.glowColor.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: item.glowColor.withOpacity(0.12),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rarity and Danger Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.glowColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.rarity.toUpperCase(),
                    style: TextStyle(
                      color: item.glowColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '💀' * item.dangerLevel,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),

            const Spacer(),

            // Glowing Phantom Icon
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.glowColor.withOpacity(0.15),
                  border: Border.all(color: item.glowColor.withOpacity(0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: item.glowColor.withOpacity(0.3),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(item.icon, color: item.glowColor, size: 30),
              ),
            ),

            const Spacer(),

            // Name and Location
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.waves, color: Colors.amber, size: 10),
                const SizedBox(width: 4),
                Text(
                  'ЭМФ: ${item.emfLevel} mG',
                  style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(AnomalyCardModel item, RegionalProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1A13),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.glowColor.withOpacity(0.2),
                      border: Border.all(color: item.glowColor),
                    ),
                    child: Icon(item.icon, color: item.glowColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${item.rarity.toUpperCase()} • Опасность: ${'💀' * item.dangerLevel}',
                          style: TextStyle(color: item.glowColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ОПИСАНИЕ СУЩНОСТИ:', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item.lore, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    const SizedBox(height: 10),
                    const Text('МЕТОД ИЗГНАНИЯ / УЯЗВИМОСТЬ:', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item.weakness, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        AudioService().playEntityWhispers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📻 Воспроизведение EVP-частоты аномалии...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.volume_up, size: 16),
                      label: const Text('Слушать EVP'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: profile.aesthetic.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        AudioService().playHolyDawnBell();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✨ ${item.name} освящен колокольным звоном!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.flare, size: 16),
                      label: const Text('Освятить'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
