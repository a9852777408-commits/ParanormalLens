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
class PhantomArtWidget extends StatelessWidget {
  final String anomalyId;
  final Color glowColor;
  final bool isCaptured;
  final double size;

  const PhantomArtWidget({
    super.key,
    required this.anomalyId,
    required this.glowColor,
    required this.isCaptured,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCaptured ? glowColor.withValues(alpha: 0.6) : Colors.white12,
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
            CustomPaint(
              size: Size(size, size),
              painter: _PhantomArtPainter(
                anomalyId: anomalyId,
                glowColor: glowColor,
                isCaptured: isCaptured,
              ),
            ),
            if (!isCaptured)
              Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: const Center(
                  child: Icon(Icons.lock, color: Colors.white30, size: 28),
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
          (isCaptured ? glowColor : Colors.white12).withValues(alpha: 0.22),
          const Color(0xFF070B09),
          Colors.black,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final ghostColor = isCaptured ? const Color(0xFF161C19) : const Color(0xFF1E2622);
    final silhouettePaint = Paint()
      ..color = ghostColor
      ..style = PaintingStyle.fill;

    final glowEyePaint = Paint()
      ..color = isCaptured ? glowColor : Colors.white24
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

    // 2. Archetype-specific atmospheric painting:
    switch (anomalyId) {
      case 'haunt_drone':
        // Winged demon gliding from dark (as in user's video screenshot)
        final path = Path();
        path.moveTo(w * 0.5, h * 0.18); // Head top
        path.quadraticBezierTo(w * 0.58, h * 0.28, w * 0.88, h * 0.32); // Right wing tip
        path.quadraticBezierTo(w * 0.72, h * 0.52, w * 0.58, h * 0.68);
        path.quadraticBezierTo(w * 0.52, h * 0.90, w * 0.5, h * 0.85); // Tail
        path.quadraticBezierTo(w * 0.48, h * 0.90, w * 0.42, h * 0.68);
        path.quadraticBezierTo(w * 0.28, h * 0.52, w * 0.12, h * 0.32); // Left wing tip
        path.quadraticBezierTo(w * 0.42, h * 0.28, w * 0.5, h * 0.18);
        canvas.drawPath(path, silhouettePaint);

        // Glowing demonic yellow-white eyes
        canvas.drawCircle(Offset(w * 0.45, h * 0.28), 2.2, glowEyePaint);
        canvas.drawCircle(Offset(w * 0.55, h * 0.28), 2.2, glowEyePaint);
        break;

      case 'paul_first':
        // Imperial 18th century silhouette with tricorn and candle
        final path = Path();
        // Tricorn hat
        path.moveTo(w * 0.5, h * 0.14);
        path.lineTo(w * 0.68, h * 0.22);
        path.lineTo(w * 0.32, h * 0.22);
        path.close();
        // Head and imperial cloak
        path.addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.28), width: w * 0.22, height: h * 0.22));
        path.moveTo(w * 0.35, h * 0.38);
        path.lineTo(w * 0.65, h * 0.38);
        path.lineTo(w * 0.78, h * 0.88);
        path.lineTo(w * 0.22, h * 0.88);
        path.close();
        canvas.drawPath(path, silhouettePaint);

        // Candle flame
        final candlePaint = Paint()
          ..color = Colors.amberAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
        canvas.drawCircle(Offset(w * 0.72, h * 0.50), 3.5, candlePaint);
        break;

      case 'inverted_raven':
        // Inverted corvid perched upside down
        final path = Path();
        path.moveTo(w * 0.5, h * 0.78); // Perched feet
        path.lineTo(w * 0.66, h * 0.55); // Wing
        path.lineTo(w * 0.58, h * 0.25); // Head pointing down
        path.lineTo(w * 0.50, h * 0.18); // Beak
        path.lineTo(w * 0.42, h * 0.25);
        path.lineTo(w * 0.34, h * 0.55);
        path.close();
        canvas.drawPath(path, silhouettePaint);

        // Amber raven eye
        canvas.drawCircle(Offset(w * 0.48, h * 0.26), 2.0, glowEyePaint);
        break;

      case 'white_cemetery_watcher':
        // Luminous white ethereal spirit
        final whiteSpiritPaint = Paint()
          ..color = (isCaptured ? Colors.white : Colors.white30).withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.42), width: w * 0.32, height: h * 0.55),
          whiteSpiritPaint,
        );
        // Head halo
        canvas.drawCircle(Offset(w * 0.5, h * 0.22), w * 0.14, whiteSpiritPaint);
        break;

      case 'flying_head_phantom':
        // Floating skull with smoke trail
        canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.18, silhouettePaint);
        final trail = Path();
        trail.moveTo(w * 0.36, h * 0.40);
        trail.quadraticBezierTo(w * 0.65, h * 0.58, w * 0.45, h * 0.85);
        trail.quadraticBezierTo(w * 0.35, h * 0.68, w * 0.55, h * 0.45);
        canvas.drawPath(trail, silhouettePaint);

        // Hollow glowing eye sockets
        canvas.drawCircle(Offset(w * 0.44, h * 0.30), 2.5, glowEyePaint);
        canvas.drawCircle(Offset(w * 0.56, h * 0.30), 2.5, glowEyePaint);
        break;

      default:
        // Slender shadowy humanoid in fog
        final path = Path();
        path.addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.24), width: w * 0.22, height: h * 0.24));
        path.moveTo(w * 0.32, h * 0.36);
        path.lineTo(w * 0.68, h * 0.36);
        path.lineTo(w * 0.74, h * 0.88);
        path.lineTo(w * 0.26, h * 0.88);
        path.close();
        canvas.drawPath(path, silhouettePaint);

        // Piercing eyes
        canvas.drawCircle(Offset(w * 0.45, h * 0.24), 2.2, glowEyePaint);
        canvas.drawCircle(Offset(w * 0.55, h * 0.24), 2.2, glowEyePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PhantomArtPainter oldDelegate) =>
      oldDelegate.isCaptured != isCaptured || oldDelegate.anomalyId != anomalyId;
}
