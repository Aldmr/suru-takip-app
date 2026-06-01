// ── Farm Model ────────────────────────────────────────────────────────────────
class Farm {
  final int? id;
  final String name;
  final String? location;

  const Farm({this.id, required this.name, this.location});
}

// ── Sheep Model ──────────────────────────────────────────────────────────────
class Sheep {
  final int? id;
  final String nfcUid;
  final String earTag;
  final String? name;
  final DateTime? birthDate;
  final String gender; // 'female' | 'male'
  final String breed;
  final String status; // 'active' | 'sick' | 'sold' | 'dead'
  final bool isPregnant;
  final String? groupName;
  final double? lastWeight;
  final int? farmId;
  final int? motherId;
  final int? fatherId;
  final int? birthRecordId;

  const Sheep({
    this.id,
    required this.nfcUid,
    required this.earTag,
    this.name,
    this.birthDate,
    required this.gender,
    required this.breed,
    this.status = 'active',
    this.isPregnant = false,
    this.groupName,
    this.lastWeight,
    this.farmId,
    this.motherId,
    this.fatherId,
    this.birthRecordId,
  });

  String get displayName => name ?? earTag;

  int? get ageYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  String get ageDetail {
    if (birthDate == null) return '?';
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    int months = now.month - birthDate!.month;
    int days = now.day - birthDate!.day;
    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years >= 1) return '$years yıl $months ay';
    return '$months ay $days gün';
  }

  Sheep copyWith({
    int? id,
    String? nfcUid,
    String? earTag,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? breed,
    String? status,
    bool? isPregnant,
    String? groupName,
    double? lastWeight,
    int? farmId,
    int? motherId,
    int? fatherId,
    int? birthRecordId,
  }) {
    return Sheep(
      id: id ?? this.id,
      nfcUid: nfcUid ?? this.nfcUid,
      earTag: earTag ?? this.earTag,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      breed: breed ?? this.breed,
      status: status ?? this.status,
      isPregnant: isPregnant ?? this.isPregnant,
      groupName: groupName ?? this.groupName,
      lastWeight: lastWeight ?? this.lastWeight,
      farmId: farmId ?? this.farmId,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      birthRecordId: birthRecordId ?? this.birthRecordId,
    );
  }

  // Demo data
  static List<Sheep> demoList = [
    Sheep(
      id: 1,
      nfcUid: '04:A3:2F:1B:9C:00:E1',
      earTag: 'TR-2021-0042',
      name: 'Pamuq',
      birthDate: DateTime(2021, 3, 15),
      gender: 'female',
      breed: 'Merinos',
      status: 'pregnant',
      lastWeight: 42.0,
    ),
    Sheep(
      id: 2,
      nfcUid: '04:B1:4A:2C:8D:01:F2',
      earTag: 'TR-2020-0018',
      name: 'Karabaş',
      birthDate: DateTime(2020, 6, 10),
      gender: 'male',
      breed: 'Kıvırcık',
      status: 'active',
      lastWeight: 58.5,
    ),
    Sheep(
      id: 3,
      nfcUid: '04:C2:5B:3D:9E:02:G3',
      earTag: 'TR-2022-0091',
      name: 'Sarıkız',
      birthDate: DateTime(2022, 1, 22),
      gender: 'female',
      breed: 'Merinos',
      status: 'sick',
      lastWeight: 38.0,
    ),
    Sheep(
      id: 4,
      nfcUid: '04:D3:6C:4E:AF:03:H4',
      earTag: 'TR-2023-0007',
      name: 'Bulut',
      birthDate: DateTime(2023, 5, 3),
      gender: 'male',
      breed: 'Akkaraman',
      status: 'active',
      lastWeight: 31.0,
    ),
  ];
}

// ── Health Record Model ───────────────────────────────────────────────────────
class HealthRecord {
  final int? id;
  final int sheepId;
  final String type; // 'vaccine' | 'disease' | 'medicine' | 'exam'
  final String name;
  final DateTime date;
  final DateTime? nextDate;
  final String? vetName;
  final String? notes;
  final String status; // 'done' | 'pending' | 'late'

  const HealthRecord({
    this.id,
    required this.sheepId,
    required this.type,
    required this.name,
    required this.date,
    this.nextDate,
    this.vetName,
    this.notes,
    this.status = 'done',
  });

  static List<HealthRecord> demoList = [
    HealthRecord(
      id: 1,
      sheepId: 1,
      type: 'vaccine',
      name: 'Brucellosis',
      date: DateTime(2024, 1, 10),
      status: 'done',
    ),
    HealthRecord(
      id: 2,
      sheepId: 1,
      type: 'vaccine',
      name: 'Enterotoksemi',
      date: DateTime(2026, 5, 28),
      status: 'pending',
    ),
    HealthRecord(
      id: 3,
      sheepId: 1,
      type: 'vaccine',
      name: 'Şap',
      date: DateTime(2026, 5, 25),
      status: 'late',
    ),
  ];
}

// ── Weight Record Model ───────────────────────────────────────────────────────
class WeightRecord {
  final int? id;
  final int sheepId;
  final DateTime date;
  final double weightKg;
  final String? notes;

  const WeightRecord({
    this.id,
    required this.sheepId,
    required this.date,
    required this.weightKg,
    this.notes,
  });

  static List<WeightRecord> demoList = [
    WeightRecord(id: 1, sheepId: 1, date: DateTime(2025, 11, 1), weightKg: 36.0),
    WeightRecord(id: 2, sheepId: 1, date: DateTime(2025, 12, 1), weightKg: 37.5),
    WeightRecord(id: 3, sheepId: 1, date: DateTime(2026, 1, 1), weightKg: 38.5),
    WeightRecord(id: 4, sheepId: 1, date: DateTime(2026, 2, 1), weightKg: 39.5),
    WeightRecord(id: 5, sheepId: 1, date: DateTime(2026, 3, 1), weightKg: 40.5),
    WeightRecord(id: 6, sheepId: 1, date: DateTime(2026, 4, 1), weightKg: 41.0),
    WeightRecord(id: 7, sheepId: 1, date: DateTime(2026, 5, 1), weightKg: 39.0),
    WeightRecord(id: 8, sheepId: 1, date: DateTime(2026, 5, 15), weightKg: 41.0),
    WeightRecord(id: 9, sheepId: 1, date: DateTime(2026, 5, 28), weightKg: 42.5),
  ];
}

// ── Breeding Record Model ─────────────────────────────────────────────────────
class BreedingRecord {
  final int? id;
  final int sheepId;
  final String type; // 'mating' | 'pregnancy' | 'birth'
  final DateTime date;
  final DateTime? expectedBirth;
  final int? lambCount;
  final String? partnerUid;
  final String? notes;

  const BreedingRecord({
    this.id,
    required this.sheepId,
    required this.type,
    required this.date,
    this.expectedBirth,
    this.lambCount,
    this.partnerUid,
    this.notes,
  });
}

// ── Financial Transaction Model ───────────────────────────────────────────────
class FinancialTransaction {
  final int? id;
  final int? farmId;
  final String type; // 'income' | 'expense'
  final String category;
  final double amount;
  final DateTime date;
  final String? note;
  final String? buyerName;
  final String scope; // 'farm' | 'sheep'
  final List<int> sheepIds;
  final DateTime createdAt;

  const FinancialTransaction({
    this.id,
    this.farmId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.buyerName,
    this.scope = 'farm',
    this.sheepIds = const [],
    required this.createdAt,
  });
}

// ── Sheep Note Model ──────────────────────────────────────────────────────────
class SheepNote {
  final int? id;
  final int sheepId;
  final DateTime date;
  final String note;

  const SheepNote({
    this.id,
    required this.sheepId,
    required this.date,
    required this.note,
  });
}

// ── Sold Sheep Record ─────────────────────────────────────────────────────────
class SoldSheepRecord {
  final Sheep sheep;
  final double? salePrice;
  final String? buyerName;
  final DateTime? saleDate;

  const SoldSheepRecord({
    required this.sheep,
    this.salePrice,
    this.buyerName,
    this.saleDate,
  });
}

// ── Lineage Models ────────────────────────────────────────────────────────────
class LitterGroup {
  final BreedingRecord? birthRecord;
  // Used when birthRecord is null but lambs have a known birthDate on their own record.
  final DateTime? fallbackDate;
  final List<Sheep> lambs;
  const LitterGroup({this.birthRecord, this.fallbackDate, required this.lambs});
}

class LineageData {
  final Sheep? mother;
  final Sheep? father;
  final List<LitterGroup> litters;
  const LineageData({this.mother, this.father, this.litters = const []});
}

// ── Alert Model ───────────────────────────────────────────────────────────────
class AlertItem {
  final String icon;
  final String title;
  final String subtitle;
  final bool isGreen;

  const AlertItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isGreen = false,
  });

  static List<AlertItem> demoList = const [
    AlertItem(
      icon: '💉',
      title: '7 koyunun aşısı bugün',
      subtitle: 'Brucellosis hatırlatma dozu',
      isGreen: false,
    ),
    AlertItem(
      icon: '🐑',
      title: 'Pamuq — doğum yaklaşıyor',
      subtitle: 'Tahmini: 3–5 gün içinde',
      isGreen: true,
    ),
  ];
}
