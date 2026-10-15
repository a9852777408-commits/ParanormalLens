import 'package:flutter/material.dart';

enum LayoutDir { ltr, rtl }

class EntitySpawnDefinition {
  final String id;
  final String name;
  final String rarity;
  final String behavior;

  const EntitySpawnDefinition({
    required this.id,
    required this.name,
    required this.rarity,
    required this.behavior,
  });
}

class SacredRelicRule {
  final List<String> recognizedObjects;
  final String glowType;
  final Color glowColor;
  final bool repelEntities;

  const SacredRelicRule({
    required this.recognizedObjects,
    required this.glowType,
    required this.glowColor,
    required this.repelEntities,
  });
}

class UIAesthetic {
  final String themeName;
  final Color primary;
  final Color accent;
  final Color background;
  final String fontFamily;

  const UIAesthetic({
    required this.themeName,
    required this.primary,
    required this.accent,
    required this.background,
    required this.fontFamily,
  });
}

class RegionalProfile {
  final String profileKey;
  final List<String> targetRegions;
  final String defaultLanguage;
  final String fallbackLanguage;
  final LayoutDir layoutDirection;
  final UIAesthetic aesthetic;
  final String bestiaryCategoryName;
  final List<EntitySpawnDefinition> spawnPool;
  final SacredRelicRule sacredRelics;

  const RegionalProfile({
    required this.profileKey,
    required this.targetRegions,
    required this.defaultLanguage,
    required this.fallbackLanguage,
    required this.layoutDirection,
    required this.aesthetic,
    required this.bestiaryCategoryName,
    required this.spawnPool,
    required this.sacredRelics,
  });
}

/// Predefined profiles matching ParanormalLens Specification
class RegionalProfiles {
  static const menaIslamic = RegionalProfile(
    profileKey: 'mena_islamic_profile',
    targetRegions: ['SA', 'AE', 'EG', 'QA', 'KW', 'OM', 'BH', 'JO', 'MA'],
    defaultLanguage: 'ar',
    fallbackLanguage: 'en',
    layoutDirection: LayoutDir.rtl,
    aesthetic: UIAesthetic(
      themeName: 'Eastern Mysticism',
      primary: Color(0xFF0D2818), // Deep emerald
      accent: Color(0xFFD4AF37),  // Arabian gold
      background: Color(0xFF050B08),
      fontFamily: 'NotoSansArabic',
    ),
    bestiaryCategoryName: 'Unseen Entities (Jinn Kind)',
    spawnPool: [
      EntitySpawnDefinition(
        id: 'jinn_marid',
        name: 'Марид (Водный/Воздушный Джинн)',
        rarity: 'rare',
        behavior: 'Distorts light and flickers shadows',
      ),
      EntitySpawnDefinition(
        id: 'jinn_ifrit',
        name: 'Ифрит (Огненная Сущность)',
        rarity: 'very_rare',
        behavior: 'Appears as red thermal haze in dark corners',
      ),
      EntitySpawnDefinition(
        id: 'jinn_ghul',
        name: 'Гуль (Обитатель безлюдных мест)',
        rarity: 'uncommon',
        behavior: 'Low crawling silhouette',
      ),
    ],
    sacredRelics: SacredRelicRule(
      recognizedObjects: [
        'islamic_crescent',
        'tasbih_prayer_beads',
        'quranic_calligraphy_frame',
      ],
      glowType: 'Divine Aura',
      glowColor: Color.fromRGBO(212, 175, 55, 0.85),
      repelEntities: true,
    ),
  );

  static const westernGothic = RegionalProfile(
    profileKey: 'western_gothic_profile',
    targetRegions: ['US', 'CA', 'GB', 'DE', 'FR', 'IT', 'ES', 'AU'],
    defaultLanguage: 'en',
    fallbackLanguage: 'en',
    layoutDirection: LayoutDir.ltr,
    aesthetic: UIAesthetic(
      themeName: 'Gothic Occult / Cyber Horror',
      primary: Color(0xFF0A0A0A),
      accent: Color(0xFF00FF66), // Acid green NV
      background: Color(0xFF000000),
      fontFamily: 'ShareTechMono',
    ),
    bestiaryCategoryName: 'Paranormal Specters & Phantoms',
    spawnPool: [
      EntitySpawnDefinition(
        id: 'shadow_person',
        name: 'Теневой Человек',
        rarity: 'common',
        behavior: 'Peripheral shadow disappearing on direct view',
      ),
      EntitySpawnDefinition(
        id: 'poltergeist',
        name: 'Полтергейст',
        rarity: 'uncommon',
        behavior: 'Static electromagnetic wave burst',
      ),
      EntitySpawnDefinition(
        id: 'demonic_wraith',
        name: 'Демонический Морок',
        rarity: 'very_rare',
        behavior: 'Slow-forming face through camera grain',
      ),
    ],
    sacredRelics: SacredRelicRule(
      recognizedObjects: [
        'christian_crucifix',
        'holy_icon',
        'church_candle',
        'rosary',
      ],
      glowType: 'Heavenly Bloom',
      glowColor: Color.fromRGBO(230, 240, 255, 0.9),
      repelEntities: true,
    ),
  );

  static const cisSlavic = RegionalProfile(
    profileKey: 'cis_slavic_profile',
    targetRegions: ['RU', 'BY', 'KZ', 'AM'],
    defaultLanguage: 'ru',
    fallbackLanguage: 'en',
    layoutDirection: LayoutDir.ltr,
    aesthetic: UIAesthetic(
      themeName: 'Slavic Occult / Industrial Dark',
      primary: Color(0xFF111116),
      accent: Color(0xFFFF9900), // Amber indicator
      background: Color(0xFF08080C),
      fontFamily: 'RobotoMono',
    ),
    bestiaryCategoryName: 'Паранормальные сущности',
    spawnPool: [
      EntitySpawnDefinition(
        id: 'shadow_silhouette',
        name: 'Теневая Сущность',
        rarity: 'common',
        behavior: 'Creeping dark outline near doorways',
      ),
      EntitySpawnDefinition(
        id: 'poltergeist_cis',
        name: 'Барабашка / Полтергейст',
        rarity: 'uncommon',
        behavior: 'Disrupts electromagnetic and acoustic readings',
      ),
      EntitySpawnDefinition(
        id: 'ancient_phantom',
        name: 'Древний Фантом',
        rarity: 'very_rare',
        behavior: 'Manifests in historical architectural zones',
      ),
    ],
    sacredRelics: SacredRelicRule(
      recognizedObjects: [
        'orthodox_cross',
        'holy_icon',
        'church_candle',
      ],
      glowType: 'Holy Gold Halo',
      glowColor: Color.fromRGBO(255, 215, 0, 0.9),
      repelEntities: true,
    ),
  );

  static List<RegionalProfile> get all => [menaIslamic, westernGothic, cisSlavic];
}
