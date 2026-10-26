import 'package:flutter/material.dart';
import '../../core/models/regional_profile.dart';
import '../../core/services/geo_adaptation_service.dart';
import '../../core/services/audio_service.dart';
import '../entity_engine/procedural_entity_spawner.dart';

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
  final double archetypeId;

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
    required this.archetypeId,
  });
}

/// Central state manager for Bestiary capture / research progress
class BestiaryService extends ChangeNotifier {
  static final BestiaryService _instance = BestiaryService._internal();
  factory BestiaryService() => _instance;
  BestiaryService._internal();

  // Initially some entities are researched, rest need to be captured by 3s lock-on!
  final Set<String> _capturedIds = {'paul_first', 'domestic_poltergeist'};

  Set<String> get capturedIds => _capturedIds;

  bool isCaptured(String id) => _capturedIds.contains(id);

  bool captureEntity(String id) {
    if (!_capturedIds.contains(id)) {
      _capturedIds.add(id);
      notifyListeners();
      return true; // Newly discovered!
    }
    return false;
  }

  void captureAllForTesting() {
    _capturedIds.addAll([
      'paul_first',
      'inverted_raven',
      'white_cemetery_watcher',
      'flying_head_phantom',
      'domestic_poltergeist',
      'jacob_bruce',
      'ostankino_prophetess',
      'banshee_evp_screamer',
      'haunt_drone',
    ]);
    notifyListeners();
  }
}

/// In-game Bestiary / Paranormal Archive Screen:
/// Supports progressive scanning capture (hold crosshair on ghost for 3 seconds)
class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  int _selectedFilterTab = 0; // 0: All, 1: Researched, 2: High Threat

  static const List<AnomalyCardModel> anomalies = [
    AnomalyCardModel(
      id: 'haunt_drone',
      name: 'Темный Летун (Из темноты)',
      rarity: 'Legendary',
      location: 'Дверной проем / Ночная улица / Гараж',
      timestamp: '03:15 AM (Внезапное появление)',
      lore: 'Массивная крылатая сущность, бесшумно выплывающая из глубокого мрака. Имеет светящиеся демонические глаза и широко распахнутые руки-крылья.',
      weakness: 'Прямой луч фонаря, освящение крестным знамением и чтение защитной молитвы.',
      emfLevel: 22.4,
      dangerLevel: 5,
      icon: Icons.air,
      glowColor: Color(0xFFFFD166),
      archetypeId: 6.0,
    ),
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
      archetypeId: 0.0,
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
      archetypeId: 5.0,
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
      archetypeId: 4.0,
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
      archetypeId: 3.0,
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
      archetypeId: 1.0,
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
      archetypeId: 0.0,
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
      archetypeId: 0.0,
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
      archetypeId: 2.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = GeoAdaptationService().activeProfile;
    final bestiaryService = BestiaryService();

    return AnimatedBuilder(
      animation: bestiaryService,
      builder: (context, _) {
        final capturedCount = bestiaryService.capturedIds.length;

        List<AnomalyCardModel> displayedList = anomalies;
        if (_selectedFilterTab == 1) {
          displayedList = anomalies.where((a) => bestiaryService.isCaptured(a.id)).toList();
        } else if (_selectedFilterTab == 2) {
          displayedList = anomalies.where((a) => a.dangerLevel >= 4).toList();
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
                Text(
                  'ИССЛЕДОВАНО: $capturedCount ИЗ ${anomalies.length} (УДЕРЖИВАЙТЕ ПРИЦЕЛ 3 СЕК ДЛЯ ЗАХВАТА)',
                  style: const TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 0.8),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  bestiaryService.captureAllForTesting();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🔓 Все сущности открыты для тестирования!')),
                  );
                },
                child: const Text('Открыть все', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildTabButton('Все (${anomalies.length})', 0, profile),
                    const SizedBox(width: 8),
                    _buildTabButton('Изученные ($capturedCount)', 1, profile),
                    const SizedBox(width: 8),
                    _buildTabButton('Опасные (💀 4-5)', 2, profile),
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
                    childAspectRatio: 0.72,
                  ),
                  itemCount: displayedList.length,
                  itemBuilder: (context, index) {
                    final item = displayedList[index];
                    final isCaptured = bestiaryService.isCaptured(item.id);
                    return _buildAnomalyCard(item, profile, isCaptured);
                  },
                ),
              ),
            ],
          ),
        );
      },
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
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyCardModel item, RegionalProfile profile, bool isCaptured) {
    return GestureDetector(
      onTap: () => _showDetailModal(item, profile, isCaptured),
      child: Container(
        decoration: BoxDecoration(
          color: isCaptured ? const Color(0xFF121E17) : const Color(0xFF0C130F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCaptured ? item.glowColor.withOpacity(0.5) : Colors.white12,
            width: isCaptured ? 1.4 : 1.0,
          ),
          boxShadow: isCaptured
              ? [
                  BoxShadow(
                    color: item.glowColor.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rarity and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCaptured ? item.glowColor.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCaptured ? item.rarity.toUpperCase() : 'НЕИЗВЕСТНО',
                    style: TextStyle(
                      color: isCaptured ? item.glowColor : Colors.white38,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  isCaptured ? Icons.check_circle : Icons.lock_outline,
                  color: isCaptured ? Colors.greenAccent : Colors.white24,
                  size: 14,
                ),
              ],
            ),

            const Spacer(),

            // Glowing Phantom Icon or Lock
            Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCaptured ? item.glowColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: isCaptured ? item.glowColor.withOpacity(0.6) : Colors.white12,
                    width: 1.5,
                  ),
                  boxShadow: isCaptured
                      ? [
                          BoxShadow(
                            color: item.glowColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isCaptured ? item.icon : Icons.help_outline,
                  color: isCaptured ? item.glowColor : Colors.white24,
                  size: 28,
                ),
              ),
            ),

            const Spacer(),

            // Name
            Text(
              isCaptured ? item.name : '??? Аномалия',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCaptured ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),

            // EMF or Scan Hint
            if (isCaptured)
              Row(
                children: [
                  const Icon(Icons.waves, color: Colors.amber, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    'ЭМФ: ${item.emfLevel} mG',
                    style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              const Text(
                'Удерживайте прицел 3с',
                style: TextStyle(color: Colors.amberAccent, fontSize: 8),
              ),

            const SizedBox(height: 2),
            Text(
              isCaptured ? item.location : 'Исследуйте пространство',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(AnomalyCardModel item, RegionalProfile profile, bool isCaptured) {
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
                      color: isCaptured ? item.glowColor.withOpacity(0.2) : Colors.white10,
                      border: Border.all(color: isCaptured ? item.glowColor : Colors.white24),
                    ),
                    child: Icon(
                      isCaptured ? item.icon : Icons.help_outline,
                      color: isCaptured ? item.glowColor : Colors.white38,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCaptured ? item.name : '??? Неисследованная сущность',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isCaptured
                              ? '${item.rarity.toUpperCase()} • Опасность: ${'💀' * item.dangerLevel}'
                              : 'ТРЕБУЕТСЯ 3-СЕКУНДНЫЙ ЗАХВАТ В ВИДОИСКАТЕЛЕ',
                          style: TextStyle(
                            color: isCaptured ? item.glowColor : Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
                    Text(
                      isCaptured ? item.lore : 'Данные зашифрованы. Наведите камеру на аномалию и удерживайте перекрестие ровно 3 секунды для снятия слепка частот.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    const Text('МЕТОД ИЗГНАНИЯ / УЯЗВИМОСТЬ:', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      isCaptured ? item.weakness : 'Освящение Животворящим Крестом и колокольным звоном.',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                    ),
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
                        // Immediately spawn this entity in viewfinder for testing!
                        ProceduralEntitySpawner().forceSpawnEntity(item.archetypeId);
                        Navigator.pop(context); // close modal
                        Navigator.pop(context); // back to camera
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚡ «${item.name}» призвана в видоискатель! Поворачивайте телефон.'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Призвать'),
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
