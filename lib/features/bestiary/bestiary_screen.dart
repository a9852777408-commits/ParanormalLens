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

  // Fresh research diary: zero pre-captured ghosts. Discovered organically by scanning!
  final Set<String> _capturedIds = <String>{};

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
      'haunt_drone',
      'shadow_stalker',
      'paul_first',
      'inverted_raven',
      'white_cemetery_watcher',
      'flying_head_phantom',
      'domestic_poltergeist',
      'jacob_bruce',
      'ostankino_prophetess',
      'banshee_evp_screamer',
    ]);
    notifyListeners();
  }
}

/// In-game Bestiary / Paranormal Archive Screen
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
      location: 'Дверной проем / Ночная комната / Гараж',
      timestamp: '03:15 AM (Внезапное появление)',
      lore: 'Массивная парящая сущность, бесшумно выплывающая из глубокого мрака. Имеет светящиеся демонические глаза и широко распахнутые руки-крылья.',
      weakness: 'Прямой луч фонаря, освящение крестным знамением и чтение защитной молитвы.',
      emfLevel: 22.4,
      dangerLevel: 5,
      icon: Icons.air,
      glowColor: Color(0xFFFFD166),
      archetypeId: 6.0,
    ),
    AnomalyCardModel(
      id: 'shadow_stalker',
      name: 'Теневой Человек',
      rarity: 'Common',
      location: 'Коридоры / Углы обзора',
      timestamp: '01:40 AM',
      lore: 'Вытянутый антропоморфный силуэт из сгустка абсолютной тьмы. Исчезает при прямом взгляде, но фиксируется в ИК-диапазоне.',
      weakness: 'Освещение свыше 500 люмен, молитва «Да воскреснет Бог».',
      emfLevel: 7.2,
      dangerLevel: 2,
      icon: Icons.person,
      glowColor: Color(0xFFE63946),
      archetypeId: 0.0,
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
      glowColor: Color(0xFF00E5FF),
      archetypeId: 7.0,
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
      glowColor: Color(0xFF7209B7),
      archetypeId: 0.0,
    ),
    AnomalyCardModel(
      id: 'ostankino_prophetess',
      name: 'Останкинская Вещунья',
      rarity: 'Mythic',
      location: 'Останкинская башня / Болота',
      timestamp: '04:12 AM',
      lore: 'Сгорбленная старуха с клюкой, возникающая перед катастрофами и пожарами. Шепчет неразборчивые пророчества.',
      weakness: 'Поклон до земли, чтение молитвы святому Трифону.',
      emfLevel: 21.0,
      dangerLevel: 5,
      icon: Icons.elderly_woman,
      glowColor: Color(0xFFF72585),
      archetypeId: 0.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final geo = GeoAdaptationService();
    final profile = geo.activeProfile;
    final bestiaryService = BestiaryService();

    return AnimatedBuilder(
      animation: bestiaryService,
      builder: (context, _) {
        final capturedSet = bestiaryService.capturedIds;
        List<AnomalyCardModel> displayedList = anomalies;

        if (_selectedFilterTab == 1) {
          displayedList = anomalies.where((a) => capturedSet.contains(a.id)).toList();
        } else if (_selectedFilterTab == 2) {
          displayedList = anomalies.where((a) => a.dangerLevel >= 4).toList();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0F0D),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F1A15),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'БЕСТИАРИЙ АНОМАЛИЙ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'ИССЛЕДОВАНО: ${capturedSet.length} ИЗ ${anomalies.length} (УДЕРЖИВАЙТЕ ПРИЦЕЛ 3 СЕК)',
                  style: TextStyle(
                    fontSize: 9,
                    color: profile.aesthetic.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  bestiaryService.captureAllForTesting();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔓 Все сущности открыты для тестирования!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Text('Открыть все', style: TextStyle(color: Colors.amber, fontSize: 11)),
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
                    _buildTabButton('Все (${anomalies.length})', 0, profile),
                    const SizedBox(width: 8),
                    _buildTabButton('Изученные (${capturedSet.length})', 1, profile),
                    const SizedBox(width: 8),
                    _buildTabButton('Опасные (💀 4-5)', 2, profile),
                  ],
                ),
              ),

              // Anomaly Grid with Ghost Illustrations
              Expanded(
                child: displayedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text(
                              'Нет изученных сущностей',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Наведите перекрестие камеры на призрака на 3 сек',
                              style: TextStyle(color: profile.aesthetic.accent, fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
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
            color: isCaptured ? item.glowColor.withValues(alpha: 0.5) : Colors.white12,
            width: isCaptured ? 1.4 : 1.0,
          ),
          boxShadow: isCaptured
              ? [
                  BoxShadow(
                    color: item.glowColor.withValues(alpha: 0.15),
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
                    color: isCaptured ? item.glowColor.withValues(alpha: 0.2) : Colors.white10,
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

            const SizedBox(height: 6),

            // Atmospheric Ghost Illustration / Silhouette
            Expanded(
              child: Center(
                child: PhantomArtWidget(
                  anomalyId: item.id,
                  glowColor: item.glowColor,
                  isCaptured: isCaptured,
                  size: 92,
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Entity Name
            Text(
              isCaptured ? item.name : '??? Неизвестная тень',
              style: TextStyle(
                color: isCaptured ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

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

              // Ghost Portrait and Header Info
              Row(
                children: [
                  PhantomArtWidget(
                    anomalyId: item.id,
                    glowColor: item.glowColor,
                    isCaptured: isCaptured,
                    size: 80,
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
                        if (isCaptured) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.timestamp,
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lore and Details
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
                    const Text(
                      'ОПИСАНИЕ И ЛОР:',
                      style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCaptured
                          ? item.lore
                          : 'Данные засекречены. Для идентификации наведите перекрестие видоискателя на фантом и удерживайте 3 секунды.',
                      style: TextStyle(
                        color: isCaptured ? Colors.white70 : Colors.white38,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (isCaptured) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'СПОСОБ ИЗГНАНИЯ / УЯЗВИМОСТЬ:',
                        style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.weakness,
                        style: TextStyle(color: profile.aesthetic.accent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons: Play EVP Audio & Summon into Viewfinder
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14241B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        AudioService().playEntityWhispers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📻 Воспроизведение EVP радиоперехвата сущности...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.graphic_eq, size: 16),
                      label: const Text('EVP Аудио', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: profile.aesthetic.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ProceduralEntitySpawner().forceSpawnEntity(item.archetypeId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2E2414),
                            content: Row(
                              children: [
                                const Icon(Icons.visibility, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(child: Text('👻 «${item.name}» материализован в видоискателе!')),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.radar, size: 16),
                      label: const Text('Призвать', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Atmospheric Ghost Art Painter
/// Generates atmospheric spectral illustrations for each specific entity archetype
/// Custom Atmospheric Ghost Art Painter & High-Res Image Renderer
/// Accurately visualizes entities matching the authentic cinematic concept artwork
class PhantomArtWidget extends StatelessWidget {
  final String anomalyId;
  final Color glowColor;
  final bool isCaptured;
  final double size;

  static const Map<String, String> _entityImageMap = {
    'haunt_drone': 'assets/images/entities/haunt_drone.jpg',
    'paul_first': 'assets/images/entities/paul_first.jpg',
    'inverted_raven': 'assets/images/entities/inverted_raven.jpg',
    'white_cemetery_watcher': 'assets/images/entities/white_cemetery_watcher.jpg',
    'flying_head_phantom': 'assets/images/entities/flying_head_phantom.jpg',
  };

  const PhantomArtWidget({
    super.key,
    required this.anomalyId,
    required this.glowColor,
    required this.isCaptured,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = _entityImageMap[anomalyId];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCaptured ? glowColor.withValues(alpha: 0.65) : Colors.white12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCaptured ? glowColor : Colors.black).withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. High-Resolution Concept Art (if available and captured)
            if (assetPath != null && isCaptured)
              Image.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => CustomPaint(
                  size: Size(size, size),
                  painter: _PhantomArtPainter(
                    anomalyId: anomalyId,
                    glowColor: glowColor,
                    isCaptured: isCaptured,
                  ),
                ),
              )
            else
              // 2. High-Fidelity Custom Vector Painter (for uncaptured or procedurals)
              CustomPaint(
                size: Size(size, size),
                painter: _PhantomArtPainter(
                  anomalyId: anomalyId,
                  glowColor: glowColor,
                  isCaptured: isCaptured,
                ),
              ),

            // 3. Mysterious Dark Shroud & Lock (when undiscovered)
            if (!isCaptured) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white38, size: 26),
                      SizedBox(height: 3),
                      Text(
                        'НЕИЗВЕСТНО',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 4. Ethereal Vignette Overlay
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isCaptured ? 0.35 : 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhantomArtPainter extends CustomPainter {
  final String anomalyId;
  final Color glowColor;
  final bool isCaptured;

  _PhantomArtPainter({
    required this.anomalyId,
    required this.glowColor,
    required this.isCaptured,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Dark Vignette / Misty Background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isCaptured ? glowColor : Colors.white12).withValues(alpha: 0.20),
          const Color(0xFF070B09),
          Colors.black,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final ghostDarkPaint = Paint()
      ..color = const Color(0xFF101412)
      ..style = PaintingStyle.fill;

    // ========================================================
    // АРХЕТИП 6: ТЕМНЫЙ ЛЕТУН (HAUNT DRONE)
    // Крылатый рогатый демон, широко раскинувший перепончатые крылья,
    // с пылающими янтарно-желтыми глазами на голове и черным дымным шлейфом
    // ========================================================
    if (anomalyId == 'haunt_drone') {
      // 1. Волюметрический черный дым внизу
      final smokePaint = Paint()
        ..color = const Color(0xFF141A16).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      final smokePath = Path();
      smokePath.moveTo(w * 0.35, h * 0.55);
      smokePath.quadraticBezierTo(w * 0.20, h * 0.80, w * 0.30, h * 0.95);
      smokePath.quadraticBezierTo(w * 0.50, h * 0.82, w * 0.70, h * 0.95);
      smokePath.quadraticBezierTo(w * 0.80, h * 0.80, w * 0.65, h * 0.55);
      smokePath.close();
      canvas.drawPath(smokePath, smokePaint);

      // 2. Массивные арочные перепончатые крылья
      final wingPath = Path();
      // Левое крыло
      wingPath.moveTo(w * 0.50, h * 0.38); // Центр груди
      wingPath.quadraticBezierTo(w * 0.35, h * 0.22, w * 0.08, h * 0.16); // Верхний изгиб к когтю
      wingPath.lineTo(w * 0.06, h * 0.20);
      wingPath.quadraticBezierTo(w * 0.18, h * 0.36, w * 0.16, h * 0.46); // Первая перепонка
      wingPath.quadraticBezierTo(w * 0.28, h * 0.44, w * 0.28, h * 0.56); // Вторая перепонка
      wingPath.quadraticBezierTo(w * 0.40, h * 0.52, w * 0.44, h * 0.62); // Третья перепонка
      // Правое крыло
      wingPath.moveTo(w * 0.50, h * 0.38);
      wingPath.quadraticBezierTo(w * 0.65, h * 0.22, w * 0.92, h * 0.16); // Верхний изгиб к когтю
      wingPath.lineTo(w * 0.94, h * 0.20);
      wingPath.quadraticBezierTo(w * 0.82, h * 0.36, w * 0.84, h * 0.46); // Первая перепонка
      wingPath.quadraticBezierTo(w * 0.72, h * 0.44, w * 0.72, h * 0.56); // Вторая перепонка
      wingPath.quadraticBezierTo(w * 0.60, h * 0.52, w * 0.56, h * 0.62); // Третья перепонка
      wingPath.close();
      canvas.drawPath(wingPath, ghostDarkPaint);

      // Костяные ребра крыльев (тонкие контурные линии)
      final ribPaint = Paint()
        ..color = Colors.white10
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.40, h * 0.35), Offset(w * 0.08, h * 0.16), ribPaint);
      canvas.drawLine(Offset(w * 0.40, h * 0.35), Offset(w * 0.16, h * 0.46), ribPaint);
      canvas.drawLine(Offset(w * 0.60, h * 0.35), Offset(w * 0.92, h * 0.16), ribPaint);
      canvas.drawLine(Offset(w * 0.60, h * 0.35), Offset(w * 0.84, h * 0.46), ribPaint);

      // 3. Демонический торс и руки
      final bodyPath = Path();
      bodyPath.moveTo(w * 0.40, h * 0.32);
      bodyPath.lineTo(w * 0.60, h * 0.32);
      bodyPath.lineTo(w * 0.56, h * 0.65);
      bodyPath.lineTo(w * 0.44, h * 0.65);
      bodyPath.close();
      canvas.drawPath(bodyPath, ghostDarkPaint);

      // 4. Демоническая голова с рогами
      final headPath = Path();
      // Левый изогнутый рог
      headPath.moveTo(w * 0.46, h * 0.24);
      headPath.quadraticBezierTo(w * 0.38, h * 0.18, w * 0.38, h * 0.12);
      headPath.quadraticBezierTo(w * 0.42, h * 0.15, w * 0.48, h * 0.22);
      // Правый изогнутый рог
      headPath.moveTo(w * 0.54, h * 0.24);
      headPath.quadraticBezierTo(w * 0.62, h * 0.18, w * 0.62, h * 0.12);
      headPath.quadraticBezierTo(w * 0.58, h * 0.15, w * 0.52, h * 0.22);
      // Череп
      headPath.addOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.26), width: w * 0.16, height: h * 0.14));
      canvas.drawPath(headPath, ghostDarkPaint);

      // 5. Пылающие демонические глаза (на высоте головы!)
      final eyeGlowPaint = Paint()
        ..color = const Color(0xFFFFB703).withValues(alpha: 0.90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      final eyeCorePaint = Paint()..color = const Color(0xFFFFFBE6);

      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.46, h * 0.26), width: 3.5, height: 2.2), eyeGlowPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.54, h * 0.26), width: 3.5, height: 2.2), eyeGlowPaint);
      canvas.drawCircle(Offset(w * 0.46, h * 0.26), 1.2, eyeCorePaint);
      canvas.drawCircle(Offset(w * 0.54, h * 0.26), 1.2, eyeCorePaint);
    }

    // ========================================================
    // АРХЕТИП 7: ПРИЗРАК ПАВЛА I (GHOST OF PAUL I)
    // Голографический бирюзово-синий контур в треуголке и мундире
    // с эполетами и орденом, со светящейся белой свечой в руке
    // ========================================================
    else if (anomalyId == 'paul_first') {
      const cyanColor = Color(0xFF00E5FF);
      final cyanGlowPaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.75)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

      final cyanBodyPaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill;

      // 1. Голографический ореол / прицел захвата AR
      final reticlePaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.28, reticlePaint);

      // 2. Знаменитая Треуголка Павла I (Tricorn Hat with cockade)
      final hatPath = Path();
      hatPath.moveTo(w * 0.50, h * 0.12); // Верхний угол треуголки
      hatPath.lineTo(w * 0.70, h * 0.22); // Правый угол
      hatPath.lineTo(w * 0.30, h * 0.22); // Левый угол
      hatPath.close();
      canvas.drawPath(hatPath, cyanBodyPaint);
      canvas.drawPath(hatPath, cyanGlowPaint);

      // Кокарда на треуголке
      canvas.drawCircle(Offset(w * 0.50, h * 0.19), 2.2, Paint()..color = Colors.white);

      // 3. Лицо и напудренный парик с буклями
      final headPath = Path();
      headPath.addOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.27), width: w * 0.18, height: h * 0.14));
      // Букли парика по бокам
      headPath.addOval(Rect.fromCenter(center: Offset(w * 0.38, h * 0.28), width: w * 0.08, height: h * 0.08));
      headPath.addOval(Rect.fromCenter(center: Offset(w * 0.62, h * 0.28), width: w * 0.08, height: h * 0.08));
      canvas.drawPath(headPath, cyanBodyPaint);
      canvas.drawPath(headPath, cyanGlowPaint);

      // 4. Мундир с эполетами и андреевской лентой
      final uniformPath = Path();
      uniformPath.moveTo(w * 0.40, h * 0.34);
      uniformPath.lineTo(w * 0.60, h * 0.34);
      // Правое плечо с эполетом
      uniformPath.lineTo(w * 0.72, h * 0.40);
      uniformPath.lineTo(w * 0.68, h * 0.78);
      uniformPath.lineTo(w * 0.32, h * 0.78);
      // Левое плечо с эполетом
      uniformPath.lineTo(w * 0.28, h * 0.40);
      uniformPath.close();
      canvas.drawPath(uniformPath, cyanBodyPaint);
      canvas.drawPath(uniformPath, cyanGlowPaint);

      // Эполеты с бахромой
      canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.38, w * 0.10, h * 0.05), cyanGlowPaint);
      canvas.drawRect(Rect.fromLTWH(w * 0.65, h * 0.38, w * 0.10, h * 0.05), cyanGlowPaint);

      // Андреевская лента через плечо
      final sashPaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.80)
        ..strokeWidth = 2.2;
      canvas.drawLine(Offset(w * 0.35, h * 0.36), Offset(w * 0.64, h * 0.68), sashPaint);

      // Орденская звезда на груди
      canvas.drawCircle(Offset(w * 0.43, h * 0.48), 2.5, Paint()..color = Colors.white);

      // 5. Рука со светящейся свечой (Подсвечник)
      final candleHand = Path();
      candleHand.moveTo(w * 0.34, h * 0.52);
      candleHand.lineTo(w * 0.22, h * 0.56); // Рука вперед
      canvas.drawPath(candleHand, cyanGlowPaint);

      // Подсвечник
      canvas.drawLine(Offset(w * 0.18, h * 0.58), Offset(w * 0.24, h * 0.58), cyanGlowPaint);
      canvas.drawLine(Offset(w * 0.21, h * 0.58), Offset(w * 0.21, h * 0.50), cyanGlowPaint);

      // Свеча и горящее пламя
      final flameGlow = Paint()
        ..color = const Color(0xFFFFD166)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5.0);
      canvas.drawCircle(Offset(w * 0.21, h * 0.46), 4.5, flameGlow);
      canvas.drawCircle(Offset(w * 0.21, h * 0.46), 2.0, Paint()..color = Colors.white);
    }

    // ========================================================
    // АРХЕТИП 5: ИНВЕРТИРОВАННЫЙ ВОРОН (INVERTED RAVEN)
    // Черная птица, висящая вниз головой на каменной раме,
    // с детальными перьями крыльев и пылающим огненно-янтарным оком
    // ========================================================
    else if (anomalyId == 'inverted_raven') {
      // 1. Каменный готический выступ/перекладина сверху
      final stonePaint = Paint()
        ..color = const Color(0xFF1E2420)
        ..strokeWidth = 3.0;
      canvas.drawLine(Offset(w * 0.25, h * 0.12), Offset(w * 0.75, h * 0.12), stonePaint);

      // 2. Когти, вцепившиеся в выступ
      final clawPaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(w * 0.46, h * 0.12), Offset(w * 0.46, h * 0.18), clawPaint);
      canvas.drawLine(Offset(w * 0.54, h * 0.12), Offset(w * 0.54, h * 0.18), clawPaint);

      // 3. Хвостовые перья, торчащие ВВЕРХ
      final tailPath = Path();
      tailPath.moveTo(w * 0.45, h * 0.32);
      tailPath.lineTo(w * 0.48, h * 0.16);
      tailPath.lineTo(w * 0.52, h * 0.16);
      tailPath.lineTo(w * 0.55, h * 0.32);
      tailPath.close();
      canvas.drawPath(tailPath, ghostDarkPaint);

      // 4. Массивное тело и сложенные блестящие крылья вниз головой
      final ravenBody = Path();
      ravenBody.moveTo(w * 0.42, h * 0.26);
      ravenBody.quadraticBezierTo(w * 0.26, h * 0.45, w * 0.34, h * 0.72); // Левое крыло
      ravenBody.lineTo(w * 0.46, h * 0.82); // К голове внизу
      ravenBody.lineTo(w * 0.54, h * 0.82);
      ravenBody.lineTo(w * 0.66, h * 0.72); // Правое крыло
      ravenBody.quadraticBezierTo(w * 0.74, h * 0.45, w * 0.58, h * 0.26);
      ravenBody.close();
      canvas.drawPath(ravenBody, ghostDarkPaint);

      // Штрихи перьев крыльев
      final featherLinePaint = Paint()
        ..color = const Color(0xFF26322A)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(w * 0.38, h * 0.40), Offset(w * 0.36, h * 0.62), featherLinePaint);
      canvas.drawLine(Offset(w * 0.44, h * 0.44), Offset(w * 0.42, h * 0.68), featherLinePaint);
      canvas.drawLine(Offset(w * 0.62, h * 0.40), Offset(w * 0.64, h * 0.62), featherLinePaint);
      canvas.drawLine(Offset(w * 0.56, h * 0.44), Offset(w * 0.58, h * 0.68), featherLinePaint);

      // 5. Опущенная вниз голова и острый клюв
      final headPath = Path();
      headPath.addOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.80), width: w * 0.18, height: h * 0.12));
      // Острый изогнутый клюв вниз
      headPath.moveTo(w * 0.46, h * 0.84);
      headPath.quadraticBezierTo(w * 0.49, h * 0.94, w * 0.48, h * 0.96);
      headPath.quadraticBezierTo(w * 0.53, h * 0.92, w * 0.54, h * 0.84);
      headPath.close();
      canvas.drawPath(headPath, ghostDarkPaint);

      // 6. Зловещее светящееся огненно-янтарное око с красной радужкой
      final eyeAuraPaint = Paint()
        ..color = const Color(0xFFFF5400).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      final eyeAmberPaint = Paint()..color = const Color(0xFFFFB703);
      final eyePupilPaint = Paint()..color = Colors.black;

      canvas.drawCircle(Offset(w * 0.53, h * 0.80), 3.5, eyeAuraPaint);
      canvas.drawCircle(Offset(w * 0.53, h * 0.80), 2.0, eyeAmberPaint);
      canvas.drawCircle(Offset(w * 0.53, h * 0.80), 0.9, eyePupilPaint);
    }

    // ========================================================
    // АРХЕТИП 4: БЕЛЫЙ КЛАДБИЩЕНСКИЙ СТРАЖ (WHITE CEMETERY WATCHER)
    // Эфирный молочно-белый силуэт человека среди могильных надгробий,
    // полупрозрачная фигура в мягком сияющем ореоле (не засвечивает экран!)
    // ========================================================
    else if (anomalyId == 'white_cemetery_watcher') {
      // 1. Силуэты старых могильных плит и крестов на фоне
      final tombstonePaint = Paint()
        ..color = const Color(0xFF0D1410)
        ..style = PaintingStyle.fill;
      // Левое надгробие
      final tomb1 = Path();
      tomb1.moveTo(w * 0.08, h * 0.90);
      tomb1.lineTo(w * 0.08, h * 0.68);
      tomb1.quadraticBezierTo(w * 0.16, h * 0.62, w * 0.24, h * 0.68);
      tomb1.lineTo(w * 0.24, h * 0.90);
      tomb1.close();
      canvas.drawPath(tomb1, tombstonePaint);

      // Правое надгробие
      final tomb2 = Path();
      tomb2.moveTo(w * 0.76, h * 0.90);
      tomb2.lineTo(w * 0.76, h * 0.72);
      tomb2.quadraticBezierTo(w * 0.84, h * 0.66, w * 0.92, h * 0.72);
      tomb2.lineTo(w * 0.92, h * 0.90);
      tomb2.close();
      canvas.drawPath(tomb2, tombstonePaint);

      // 2. Сияющий ореол вокруг призрака (мягкий градиент)
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: isCaptured ? 0.35 : 0.15),
            const Color(0xFFC8E6C9).withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(w * 0.50, h * 0.45), radius: w * 0.40));
      canvas.drawCircle(Offset(w * 0.50, h * 0.45), w * 0.40, haloPaint);

      // 3. Грациозный полупрозрачный человеческий силуэт
      final spiritPaint = Paint()
        ..color = (isCaptured ? const Color(0xFFE8F4F8) : const Color(0xFFA0B8B0)).withValues(alpha: 0.78)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

      final personPath = Path();
      // Голова
      personPath.addOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.26), width: w * 0.14, height: h * 0.13));
      // Шея и плечи
      personPath.moveTo(w * 0.46, h * 0.32);
      personPath.lineTo(w * 0.36, h * 0.38); // Левое плечо
      personPath.quadraticBezierTo(w * 0.34, h * 0.52, w * 0.40, h * 0.62); // Торс
      personPath.lineTo(w * 0.42, h * 0.88); // Левая нога
      personPath.lineTo(w * 0.48, h * 0.88);
      personPath.lineTo(w * 0.50, h * 0.68); // Разделение ног
      personPath.lineTo(w * 0.52, h * 0.88);
      personPath.lineTo(w * 0.58, h * 0.88); // Правая нога
      personPath.lineTo(w * 0.60, h * 0.62);
      personPath.quadraticBezierTo(w * 0.66, h * 0.52, w * 0.64, h * 0.38); // Правое плечо
      personPath.lineTo(w * 0.54, h * 0.32);
      personPath.close();
      canvas.drawPath(personPath, spiritPaint);

      // Внутреннее светящееся ядро
      final innerCorePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5);
      canvas.drawCircle(Offset(w * 0.50, h * 0.26), w * 0.04, innerCorePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.44), width: w * 0.08, height: h * 0.16), innerCorePaint);
    }

    // ========================================================
    // АРХЕТИП 3: ЛЕТАЮЩИЙ МОРОК (FLYING MOROK / FLOATING SKULL)
    // Анатомический человеческий череп с глазницами и зубами,
    // за которым стелется длинный шлейф клубящегося черного дыма
    // ========================================================
    else if (anomalyId == 'flying_head_phantom') {
      // 1. Длинный вихревой шлейф черного дыма назад и вправо
      final smokePath = Path();
      smokePath.moveTo(w * 0.42, h * 0.36);
      smokePath.quadraticBezierTo(w * 0.62, h * 0.20, w * 0.88, h * 0.18);
      smokePath.quadraticBezierTo(w * 0.98, h * 0.42, w * 0.78, h * 0.60);
      smokePath.quadraticBezierTo(w * 0.65, h * 0.72, w * 0.42, h * 0.58);
      smokePath.close();

      final smokePaint = Paint()
        ..color = const Color(0xFF141A16).withValues(alpha: 0.88)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(smokePath, smokePaint);

      // Дополнительные витки дыма
      final tendrilPaint = Paint()
        ..color = Colors.black87
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(Offset(w * 0.62, h * 0.35), w * 0.12, tendrilPaint);
      canvas.drawCircle(Offset(w * 0.78, h * 0.38), w * 0.10, tendrilPaint);
      canvas.drawCircle(Offset(w * 0.88, h * 0.26), w * 0.08, tendrilPaint);

      // 2. Костяной свод черепа
      final skullBonePaint = Paint()
        ..color = (isCaptured ? const Color(0xFFD6DDD8) : const Color(0xFF6C7570))
        ..style = PaintingStyle.fill;

      final skullPath = Path();
      // Купол черепа
      skullPath.moveTo(w * 0.32, h * 0.30);
      skullPath.quadraticBezierTo(w * 0.42, h * 0.22, w * 0.52, h * 0.30);
      // Скуловая кость
      skullPath.quadraticBezierTo(w * 0.56, h * 0.42, w * 0.48, h * 0.50);
      // Верхняя челюсть и зубы
      skullPath.lineTo(w * 0.48, h * 0.58);
      skullPath.lineTo(w * 0.36, h * 0.58);
      // Нижний контур скулы к затылку
      skullPath.lineTo(w * 0.36, h * 0.50);
      skullPath.quadraticBezierTo(w * 0.26, h * 0.44, w * 0.32, h * 0.30);
      skullPath.close();
      canvas.drawPath(skullPath, skullBonePaint);

      // 3. Глазницы (темные провалы со спектральным отблеском)
      final socketPaint = Paint()..color = const Color(0xFF0A0F0D);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.38, h * 0.40), width: 4.5, height: 6.0), socketPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.47, h * 0.40), width: 4.5, height: 6.0), socketPaint);

      // Носовая полость (грушевидная апертура)
      final nosePath = Path();
      nosePath.moveTo(w * 0.42, h * 0.45);
      nosePath.lineTo(w * 0.44, h * 0.49);
      nosePath.lineTo(w * 0.40, h * 0.49);
      nosePath.close();
      canvas.drawPath(nosePath, socketPaint);

      // Зубные штрихи
      final toothPaint = Paint()
        ..color = const Color(0xFF0A0F0D)
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(w * 0.39, h * 0.53), Offset(w * 0.39, h * 0.58), toothPaint);
      canvas.drawLine(Offset(w * 0.42, h * 0.53), Offset(w * 0.42, h * 0.58), toothPaint);
      canvas.drawLine(Offset(w * 0.45, h * 0.53), Offset(w * 0.45, h * 0.58), toothPaint);

      // Легкое свечение в глазницах
      final eyeGlow = Paint()
        ..color = const Color(0xFF52B788).withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
      canvas.drawCircle(Offset(w * 0.38, h * 0.40), 1.2, eyeGlow);
      canvas.drawCircle(Offset(w * 0.47, h * 0.40), 1.2, eyeGlow);
    }

    // ========================================================
    // ДРУГИЕ СУЩНОСТИ (Теневой человек, Барабашка и т.д.)
    // ========================================================
    else {
      final path = Path();
      path.addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.24), width: w * 0.22, height: h * 0.24));
      path.moveTo(w * 0.32, h * 0.36);
      path.lineTo(w * 0.68, h * 0.36);
      path.lineTo(w * 0.74, h * 0.88);
      path.lineTo(w * 0.26, h * 0.88);
      path.close();
      canvas.drawPath(path, ghostDarkPaint);

      final glowEyePaint = Paint()
        ..color = isCaptured ? glowColor : Colors.white24
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);
      canvas.drawCircle(Offset(w * 0.45, h * 0.24), 2.2, glowEyePaint);
      canvas.drawCircle(Offset(w * 0.55, h * 0.24), 2.2, glowEyePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PhantomArtPainter oldDelegate) =>
      oldDelegate.isCaptured != isCaptured || oldDelegate.anomalyId != anomalyId;
}
