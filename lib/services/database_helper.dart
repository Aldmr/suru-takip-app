import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'suru_takip.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE farms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sheep(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nfcUid TEXT NOT NULL,
        earTag TEXT NOT NULL,
        name TEXT,
        birthDate TEXT,
        gender TEXT NOT NULL,
        breed TEXT NOT NULL,
        status TEXT,
        isPregnant INTEGER NOT NULL DEFAULT 0,
        groupName TEXT,
        lastWeight REAL,
        farmId INTEGER,
        motherId INTEGER,
        fatherId INTEGER,
        birthRecordId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE health_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sheepId INTEGER NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        nextDate TEXT,
        vetName TEXT,
        notes TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sheepId INTEGER NOT NULL,
        date TEXT NOT NULL,
        weightKg REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE breeding_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sheepId INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        expectedBirth TEXT,
        lambCount INTEGER,
        partnerUid TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE financial_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmId INTEGER,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        buyerName TEXT,
        scope TEXT NOT NULL DEFAULT 'farm',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_sheep(
        transactionId INTEGER NOT NULL,
        sheepId INTEGER NOT NULL,
        PRIMARY KEY (transactionId, sheepId)
      )
    ''');

    await db.execute('''
      CREATE TABLE sheep_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sheepId INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE breeding_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sheepId INTEGER NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          expectedBirth TEXT,
          lambCount INTEGER,
          partnerUid TEXT,
          notes TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE farms(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          location TEXT,
          createdAt TEXT
        )
      ''');
      await db.rawInsert(
        "INSERT INTO farms(name, createdAt) VALUES('Varsayılan Çiftlik', '${DateTime.now().toIso8601String()}')",
      );
      await db.execute('ALTER TABLE sheep ADD COLUMN farmId INTEGER');
      final idRes = await db.rawQuery('SELECT id FROM farms ORDER BY id LIMIT 1');
      final defaultFarmId = idRes.isNotEmpty ? (idRes.first['id'] as int) : 1;
      await db.rawUpdate('UPDATE sheep SET farmId = $defaultFarmId');
    }

    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE sheep ADD COLUMN isPregnant INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sheep_notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sheepId INTEGER NOT NULL,
          date TEXT NOT NULL,
          note TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE sheep ADD COLUMN motherId INTEGER');
      await db.execute('ALTER TABLE sheep ADD COLUMN fatherId INTEGER');
      await db.execute('ALTER TABLE sheep ADD COLUMN birthRecordId INTEGER');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS financial_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          farmId INTEGER,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          buyerName TEXT,
          scope TEXT NOT NULL DEFAULT 'farm',
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_sheep(
          transactionId INTEGER NOT NULL,
          sheepId INTEGER NOT NULL,
          PRIMARY KEY (transactionId, sheepId)
        )
      ''');
    }
  }

  // --- Farm CRUD ---
  Future<List<Farm>> getAllFarms() async {
    final db = await database;
    final rows = await db.query('farms', orderBy: 'id');
    return rows.map((r) => Farm(
      id: r['id'] as int,
      name: r['name'] as String,
      location: r['location'] as String?,
    )).toList();
  }

  Future<int> insertFarm(Farm farm) async {
    final db = await database;
    return await db.insert('farms', {
      'name': farm.name,
      'location': farm.location,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> renameFarm(int id, String name) async {
    final db = await database;
    await db.update('farms', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  // --- Sheep CRUD ---
  Future<String> getNextEarTag({required int farmId}) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT earTag FROM sheep WHERE farmId = ?', [farmId]);
    int maxNum = 0;
    for (final row in rows) {
      final tag = (row['earTag'] as String).trim();
      final n = int.tryParse(tag);
      if (n != null && n > maxNum) maxNum = n;
    }
    return (maxNum + 1).toString().padLeft(5, '0');
  }

  Future<bool> isEarTagTaken(String earTag, {int? farmId, int? excludeId}) async {
    final db = await database;
    final conditions = ['earTag = ?'];
    final args = <Object>[earTag];
    if (farmId != null) {
      conditions.add('farmId = ?');
      args.add(farmId);
    }
    if (excludeId != null) {
      conditions.add('id != ?');
      args.add(excludeId);
    }
    final rows = await db.query('sheep',
        columns: ['id'],
        where: conditions.join(' AND '),
        whereArgs: args,
        limit: 1);
    return rows.isNotEmpty;
  }

  Future<int> insertSheep(Sheep s) async {
    final db = await database;
    return await db.insert('sheep', {
      'nfcUid': s.nfcUid,
      'earTag': s.earTag,
      'name': s.name,
      'birthDate': s.birthDate?.toIso8601String(),
      'gender': s.gender,
      'breed': s.breed,
      'status': s.status,
      'isPregnant': s.isPregnant ? 1 : 0,
      'groupName': s.groupName,
      'lastWeight': s.lastWeight,
      'farmId': s.farmId,
      'motherId': s.motherId,
      'fatherId': s.fatherId,
      'birthRecordId': s.birthRecordId,
    });
  }

  Future<void> syncSheepStatuses({int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? 'AND farmId = $farmId' : '';

    // ── Hastalık ─────────────────────────────────────────────────────────────
    // Aktif (pending) hastalık kaydı olan koyunları 'sick' yap
    await db.rawUpdate('''
      UPDATE sheep
      SET status = 'sick'
      WHERE status = 'active' $fc
      AND id IN (
        SELECT DISTINCT sheepId FROM health_records
        WHERE type = 'disease' AND status = 'pending'
      )
    ''');

    // Pending hastalık kaydı kalmayan koyunları tekrar 'active' yap
    await db.rawUpdate('''
      UPDATE sheep
      SET status = 'active'
      WHERE status = 'sick' $fc
      AND id NOT IN (
        SELECT DISTINCT sheepId FROM health_records
        WHERE type = 'disease' AND status = 'pending'
      )
    ''');

    // ── Gebelik ──────────────────────────────────────────────────────────────
    // Mark as pregnant: has a pregnancy record more recent than any birth record
    await db.rawUpdate('''
      UPDATE sheep
      SET isPregnant = 1
      WHERE status NOT IN ('sold', 'dead') $fc
      AND id IN (
        SELECT p.sheepId FROM breeding_records p
        WHERE p.type = 'pregnancy'
        AND p.date > COALESCE(
          (SELECT MAX(b.date) FROM breeding_records b
           WHERE b.type = 'birth' AND b.sheepId = p.sheepId), '0'
        )
      )
    ''');

    // Clear pregnancy: birth record is more recent than latest pregnancy record
    await db.rawUpdate('''
      UPDATE sheep
      SET isPregnant = 0
      WHERE isPregnant = 1 $fc
      AND id IN (
        SELECT b.sheepId FROM breeding_records b
        WHERE b.type = 'birth'
        AND b.date >= COALESCE(
          (SELECT MAX(p.date) FROM breeding_records p
           WHERE p.type = 'pregnancy' AND p.sheepId = b.sheepId), '0'
        )
      )
    ''');
  }

  Future<List<Sheep>> getAllSheep({int? farmId, bool activeOnly = false}) async {
    final db = await database;
    final conditions = <String>[];
    if (activeOnly) conditions.add("status NOT IN ('sold', 'dead')");
    if (farmId != null) conditions.add('farmId = $farmId');
    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final rows = await db.query('sheep', where: where, orderBy: 'earTag');
    return rows.map(_rowToSheep).toList();
  }

  Future<List<String>> getGroups({int? farmId}) async {
    final db = await database;
    final fc = farmId != null
        ? 'WHERE farmId = $farmId AND groupName IS NOT NULL'
        : 'WHERE groupName IS NOT NULL';
    final rows = await db.rawQuery(
        'SELECT DISTINCT groupName FROM sheep $fc ORDER BY groupName');
    return rows.map((r) => r['groupName'] as String).toList();
  }

  Future<List<SoldSheepRecord>> getSoldSheepWithInfo({int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? "AND s.farmId = $farmId" : "";
    final rows = await db.rawQuery('''
      SELECT s.*,
        (SELECT ft.amount / (SELECT COUNT(*) FROM transaction_sheep ts2 WHERE ts2.transactionId = ft.id)
         FROM financial_transactions ft
         JOIN transaction_sheep ts ON ts.transactionId = ft.id
         WHERE ts.sheepId = s.id AND ft.category = 'animal_sale'
         ORDER BY ft.date DESC LIMIT 1) as salePrice,
        (SELECT ft.buyerName FROM financial_transactions ft
         JOIN transaction_sheep ts ON ts.transactionId = ft.id
         WHERE ts.sheepId = s.id AND ft.category = 'animal_sale'
         ORDER BY ft.date DESC LIMIT 1) as saleBuyerName,
        (SELECT ft.date FROM financial_transactions ft
         JOIN transaction_sheep ts ON ts.transactionId = ft.id
         WHERE ts.sheepId = s.id AND ft.category = 'animal_sale'
         ORDER BY ft.date DESC LIMIT 1) as saleDate
      FROM sheep s
      WHERE s.status = 'sold' $fc
      ORDER BY saleDate DESC, s.earTag
    ''');
    return rows.map((r) => SoldSheepRecord(
      sheep: _rowToSheep(r),
      salePrice: r['salePrice'] == null ? null : (r['salePrice'] as num).toDouble(),
      buyerName: r['saleBuyerName'] as String?,
      saleDate: r['saleDate'] == null ? null : DateTime.tryParse(r['saleDate'] as String),
    )).toList();
  }

  Future<Sheep?> getSheepByNfc(String uid) async {
    final db = await database;
    final rows = await db.query('sheep', where: 'nfcUid = ?', whereArgs: [uid]);
    if (rows.isEmpty) return null;
    return _rowToSheep(rows.first);
  }

  Future<Sheep?> getSheepById(int id) async {
    final db = await database;
    final rows = await db.query('sheep', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToSheep(rows.first);
  }

  Sheep _rowToSheep(Map<String, Object?> r) => Sheep(
    id: r['id'] as int?,
    nfcUid: r['nfcUid'] as String,
    earTag: r['earTag'] as String,
    name: r['name'] as String?,
    birthDate: r['birthDate'] == null ? null : DateTime.tryParse(r['birthDate'] as String),
    gender: r['gender'] as String,
    breed: r['breed'] as String,
    status: (r['status'] as String?) ?? 'active',
    isPregnant: (r['isPregnant'] as int? ?? 0) == 1,
    groupName: r['groupName'] as String?,
    lastWeight: r['lastWeight'] == null ? null : (r['lastWeight'] as num).toDouble(),
    farmId: r['farmId'] as int?,
    motherId: r['motherId'] as int?,
    fatherId: r['fatherId'] as int?,
    birthRecordId: r['birthRecordId'] as int?,
  );

  // --- Lineage ---

  // Returns true if candidateId is a descendant (direct or indirect) of ancestorId.
  Future<bool> _isDescendant(Database db, int ancestorId, int candidateId) async {
    final visited = <int>{};
    final queue = [ancestorId];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      visited.add(current);
      final rows = await db.query(
        'sheep',
        columns: ['id'],
        where: 'motherId = ? OR fatherId = ?',
        whereArgs: [current, current],
      );
      for (final row in rows) {
        final id = row['id'] as int;
        if (id == candidateId) return true;
        if (!visited.contains(id)) queue.add(id);
      }
    }
    return false;
  }

  // Returns null on success.
  // Returns 'circular' if the relationship would create a cycle.
  // Returns the conflicting earTag string if a different parent already exists (non-force mode).
  Future<String?> setSheepParent({
    required int sheepId,
    required int parentId,
    required String role,
    bool force = false,
  }) async {
    if (sheepId == parentId) return 'circular';
    final db = await database;
    // parentId cannot be a descendant of sheepId — that would create a cycle.
    if (await _isDescendant(db, sheepId, parentId)) return 'circular';
    final column = role == 'mother' ? 'motherId' : 'fatherId';
    if (!force) {
      final existing = await db.query('sheep', columns: [column], where: 'id = ?', whereArgs: [sheepId]);
      if (existing.isNotEmpty) {
        final existingId = existing.first[column] as int?;
        if (existingId != null && existingId != parentId) {
          final existingParent = await getSheepById(existingId);
          return existingParent?.earTag ?? existingId.toString();
        }
      }
    }
    await db.update('sheep', {column: parentId}, where: 'id = ?', whereArgs: [sheepId]);
    return null;
  }

  Future<void> removeSheepParent({required int sheepId, required String role}) async {
    final db = await database;
    final column = role == 'mother' ? 'motherId' : 'fatherId';
    await db.update('sheep', {column: null}, where: 'id = ?', whereArgs: [sheepId]);
  }

  Future<void> linkLambToBirth({required int sheepId, required int birthRecordId}) async {
    final db = await database;
    await db.update('sheep', {'birthRecordId': birthRecordId}, where: 'id = ?', whereArgs: [sheepId]);
  }

  Future<LineageData> getLineageData(int sheepId) async {
    final db = await database;
    final thisSheep = await getSheepById(sheepId);
    if (thisSheep == null) return const LineageData();

    Sheep? mother;
    if (thisSheep.motherId != null) mother = await getSheepById(thisSheep.motherId!);

    Sheep? father;
    if (thisSheep.fatherId != null) father = await getSheepById(thisSheep.fatherId!);

    final offspringRows = await db.query(
      'sheep',
      where: 'motherId = ? OR fatherId = ?',
      whereArgs: [sheepId, sheepId],
      orderBy: 'birthRecordId ASC, earTag ASC',
    );
    final offspring = offspringRows.map(_rowToSheep).toList();

    final Map<int?, List<Sheep>> grouped = {};
    for (final lamb in offspring) {
      grouped.putIfAbsent(lamb.birthRecordId, () => []).add(lamb);
    }

    final litters = <LitterGroup>[];
    for (final entry in grouped.entries) {
      if (entry.key != null) {
        BreedingRecord? birthRecord;
        final rows = await db.query('breeding_records', where: 'id = ?', whereArgs: [entry.key]);
        if (rows.isNotEmpty) {
          final row = rows.first;
          birthRecord = BreedingRecord(
            id: row['id'] as int?,
            sheepId: row['sheepId'] as int,
            type: row['type'] as String,
            date: DateTime.parse(row['date'] as String),
            expectedBirth: row['expectedBirth'] == null ? null : DateTime.tryParse(row['expectedBirth'] as String),
            lambCount: row['lambCount'] as int?,
            partnerUid: row['partnerUid'] as String?,
            notes: row['notes'] as String?,
          );
        }
        litters.add(LitterGroup(birthRecord: birthRecord, lambs: entry.value));
      } else {
        // No breeding record — sub-group by the lamb's own birthDate so each
        // unique date gets its own header row instead of a single "unknown" block.
        final Map<String, List<Sheep>> byDate = {};
        for (final lamb in entry.value) {
          final key = lamb.birthDate?.toIso8601String() ?? '';
          byDate.putIfAbsent(key, () => []).add(lamb);
        }
        for (final dateEntry in byDate.entries) {
          final date = dateEntry.key.isNotEmpty ? DateTime.tryParse(dateEntry.key) : null;
          litters.add(LitterGroup(fallbackDate: date, lambs: dateEntry.value));
        }
      }
    }

    litters.sort((a, b) {
      if (a.birthRecord == null && b.birthRecord == null) return 0;
      if (a.birthRecord == null) return 1;
      if (b.birthRecord == null) return -1;
      return b.birthRecord!.date.compareTo(a.birthRecord!.date);
    });

    return LineageData(mother: mother, father: father, litters: litters);
  }

  Future<int> updateSheep(Sheep s) async {
    final db = await database;
    if (s.id == null) return 0;
    return await db.update('sheep', {
      'nfcUid': s.nfcUid,
      'earTag': s.earTag,
      'name': s.name,
      'birthDate': s.birthDate?.toIso8601String(),
      'gender': s.gender,
      'breed': s.breed,
      'status': s.status,
      'isPregnant': s.isPregnant ? 1 : 0,
      'groupName': s.groupName,
      'lastWeight': s.lastWeight,
      'farmId': s.farmId,
      'motherId': s.motherId,
      'fatherId': s.fatherId,
      'birthRecordId': s.birthRecordId,
    }, where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteSheep(int id) async {
    final db = await database;
    return await db.delete('sheep', where: 'id = ?', whereArgs: [id]);
  }

  // --- HealthRecord CRUD ---
  Future<int> insertHealthRecord(HealthRecord h) async {
    final db = await database;
    final id = await db.insert('health_records', {
      'sheepId': h.sheepId,
      'type': h.type,
      'name': h.name,
      'date': h.date.toIso8601String(),
      'nextDate': h.nextDate?.toIso8601String(),
      'vetName': h.vetName,
      'notes': h.notes,
      'status': h.status,
    });
    if (h.type == 'disease') {
      await db.update('sheep', {'status': 'sick'},
          where: 'id = ? AND status NOT IN (?, ?)',
          whereArgs: [h.sheepId, 'sold', 'dead']);
    }
    return id;
  }

  Future<void> resolveHealthRecord(int recordId, int sheepId) async {
    final db = await database;
    // nextDate yoksa bitiş tarihi olarak bugünü ata
    final existing = await db.query('health_records',
        columns: ['nextDate'], where: 'id = ?', whereArgs: [recordId]);
    final hasEndDate = existing.isNotEmpty && existing.first['nextDate'] != null;
    final updateMap = <String, Object?>{
      'status': 'done',
      if (!hasEndDate) 'nextDate': DateTime.now().toIso8601String(),
    };
    await db.update('health_records', updateMap, where: 'id = ?', whereArgs: [recordId]);
    final pending = await db.query('health_records',
        where: 'sheepId = ? AND type = ? AND status = ?',
        whereArgs: [sheepId, 'disease', 'pending']);
    if (pending.isEmpty) {
      await db.update('sheep', {'status': 'active'},
          where: 'id = ? AND status = ?', whereArgs: [sheepId, 'sick']);
    }
  }

  Future<int> insertSheepNote(SheepNote n) async {
    final db = await database;
    return await db.insert('sheep_notes', {
      'sheepId': n.sheepId,
      'date': n.date.toIso8601String(),
      'note': n.note,
    });
  }

  Future<List<SheepNote>> getNotesBySheepId(int sheepId) async {
    final db = await database;
    final rows = await db.query(
      'sheep_notes',
      where: 'sheepId = ?',
      whereArgs: [sheepId],
      orderBy: 'date DESC',
    );
    return rows.map((r) => SheepNote(
      id: r['id'] as int?,
      sheepId: r['sheepId'] as int,
      date: DateTime.parse(r['date'] as String),
      note: r['note'] as String,
    )).toList();
  }

  Future<List<HealthRecord>> getHealthRecordsBySheepId(int sheepId) async {
    final db = await database;
    final rows = await db.query(
      'health_records',
      where: 'sheepId = ?',
      whereArgs: [sheepId],
      orderBy: 'date DESC',
    );
    return rows.map((r) => HealthRecord(
      id: r['id'] as int?,
      sheepId: r['sheepId'] as int,
      type: r['type'] as String,
      name: r['name'] as String,
      date: DateTime.parse(r['date'] as String),
      nextDate: r['nextDate'] == null ? null : DateTime.tryParse(r['nextDate'] as String),
      vetName: r['vetName'] as String?,
      notes: r['notes'] as String?,
      status: (r['status'] as String?) ?? 'done',
    )).toList();
  }

  // --- WeightRecord CRUD ---
  Future<int> insertWeightRecord(WeightRecord w) async {
    final db = await database;
    return await db.insert('weight_records', {
      'sheepId': w.sheepId,
      'date': w.date.toIso8601String(),
      'weightKg': w.weightKg,
      'notes': w.notes,
    });
  }

  Future<List<WeightRecord>> getWeightRecordsBySheepId(int sheepId) async {
    final db = await database;
    final rows = await db.query(
      'weight_records',
      where: 'sheepId = ?',
      whereArgs: [sheepId],
      orderBy: 'date ASC',
    );
    return rows.map((r) => WeightRecord(
      id: r['id'] as int?,
      sheepId: r['sheepId'] as int,
      date: DateTime.parse(r['date'] as String),
      weightKg: (r['weightKg'] as num).toDouble(),
      notes: r['notes'] as String?,
    )).toList();
  }

  // --- BreedingRecord CRUD ---
  Future<int> insertBreedingRecord(BreedingRecord r) async {
    final db = await database;
    return await db.insert('breeding_records', {
      'sheepId': r.sheepId,
      'type': r.type,
      'date': r.date.toIso8601String(),
      'expectedBirth': r.expectedBirth?.toIso8601String(),
      'lambCount': r.lambCount,
      'partnerUid': r.partnerUid,
      'notes': r.notes,
    });
  }

  Future<List<BreedingRecord>> getBreedingRecordsBySheepId(int sheepId) async {
    final db = await database;
    final rows = await db.query(
      'breeding_records',
      where: 'sheepId = ?',
      whereArgs: [sheepId],
      orderBy: 'date DESC',
    );
    return rows.map((r) => BreedingRecord(
      id: r['id'] as int?,
      sheepId: r['sheepId'] as int,
      type: r['type'] as String,
      date: DateTime.parse(r['date'] as String),
      expectedBirth: r['expectedBirth'] == null ? null : DateTime.tryParse(r['expectedBirth'] as String),
      lambCount: r['lambCount'] as int?,
      partnerUid: r['partnerUid'] as String?,
      notes: r['notes'] as String?,
    )).toList();
  }

  // --- Stats for dashboard ---
  Future<Map<String, int>> getSheepStats({int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? " AND farmId = $farmId" : "";
    final fcJoin = farmId != null ? " AND s.farmId = $farmId" : "";
    final all = await db.rawQuery(
      "SELECT COUNT(*) as c FROM sheep WHERE status NOT IN ('sold','dead')$fc",
    );
    final pregnant = await db.rawQuery(
      "SELECT COUNT(*) as c FROM sheep WHERE isPregnant = 1 AND status NOT IN ('sold','dead')$fc",
    );
    final sick = await db.rawQuery(
      "SELECT COUNT(*) as c FROM sheep WHERE status = 'sick'$fc",
    );
    final vaccineNeeded = await db.rawQuery(
      "SELECT COUNT(DISTINCT h.sheepId) as c FROM health_records h "
      "JOIN sheep s ON s.id = h.sheepId "
      "WHERE h.type = 'vaccine' AND s.status NOT IN ('sold', 'dead')$fcJoin "
      "AND (h.status = 'pending' "
      "OR (h.status = 'done' AND h.nextDate IS NOT NULL AND h.nextDate > ?))",
      [DateTime.now().toIso8601String()],
    );
    return {
      'total': Sqflite.firstIntValue(all) ?? 0,
      'pregnant': Sqflite.firstIntValue(pregnant) ?? 0,
      'sick': Sqflite.firstIntValue(sick) ?? 0,
      'vaccineNeeded': Sqflite.firstIntValue(vaccineNeeded) ?? 0,
    };
  }

  // --- Dashboard alerts ---
  Future<List<AlertItem>> getUpcomingAlerts({int? farmId}) async {
    final db = await database;
    final now = DateTime.now();
    final alerts = <AlertItem>[];
    final farmFilter = farmId != null ? " AND s.farmId = $farmId" : "";

    // Overdue: pending vaccines whose date has passed OR done vaccines whose nextDate has passed
    final late = await db.rawQuery(
      "SELECT COUNT(DISTINCT h.sheepId) as c FROM health_records h "
      "JOIN sheep s ON s.id = h.sheepId "
      "WHERE h.type = 'vaccine' AND s.status NOT IN ('sold', 'dead')$farmFilter "
      "AND ((h.status = 'pending' AND h.date < ?) "
      "OR (h.status = 'done' AND h.nextDate IS NOT NULL AND h.nextDate < ?))",
      [now.toIso8601String(), now.toIso8601String()],
    );
    final lateCount = Sqflite.firstIntValue(late) ?? 0;
    if (lateCount > 0) {
      alerts.add(AlertItem(
        icon: '⚠️',
        title: '$lateCount koyunun aşısı gecikti',
        subtitle: 'Acil müdahale gerekiyor',
      ));
    }

    // Upcoming within 7 days: pending vaccines OR done vaccines with nextDate in the next 7 days
    final upcoming = await db.rawQuery(
      "SELECT COUNT(DISTINCT h.sheepId) as c FROM health_records h "
      "JOIN sheep s ON s.id = h.sheepId "
      "WHERE h.type = 'vaccine' AND s.status NOT IN ('sold', 'dead')$farmFilter "
      "AND ((h.status = 'pending' AND h.date >= ? AND h.date <= ?) "
      "OR (h.status = 'done' AND h.nextDate IS NOT NULL AND h.nextDate >= ? AND h.nextDate <= ?))",
      [
        now.toIso8601String(), now.add(const Duration(days: 7)).toIso8601String(),
        now.toIso8601String(), now.add(const Duration(days: 7)).toIso8601String(),
      ],
    );
    final upcomingCount = Sqflite.firstIntValue(upcoming) ?? 0;
    if (upcomingCount > 0) {
      alerts.add(AlertItem(
        icon: '💉',
        title: '$upcomingCount koyunun aşısı bu hafta',
        subtitle: '7 gün içinde yapılmalı',
      ));
    }

    // Upcoming births within 10 days
    final births = await db.rawQuery(
      "SELECT s.name, s.earTag, b.expectedBirth FROM breeding_records b "
      "JOIN sheep s ON s.id = b.sheepId "
      "WHERE b.type = 'pregnancy' AND b.expectedBirth IS NOT NULL AND b.expectedBirth <= ?$farmFilter "
      "ORDER BY b.expectedBirth ASC",
      [now.add(const Duration(days: 10)).toIso8601String()],
    );
    for (final row in births) {
      final name = (row['name'] as String?) ?? (row['earTag'] as String);
      final birth = DateTime.tryParse(row['expectedBirth'] as String);
      final days = birth == null
          ? '?'
          : '${birth.difference(DateTime(now.year, now.month, now.day)).inDays}';
      alerts.add(AlertItem(
        icon: '🐑',
        title: '$name — doğum yaklaşıyor',
        subtitle: 'Tahmini: $days gün içinde',
        isGreen: true,
      ));
    }

    return alerts;
  }

  // --- Reports ---
  Future<Map<String, int>> getBreedDistribution({int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? " AND farmId = $farmId" : "";
    final rows = await db.rawQuery(
      "SELECT breed, COUNT(*) as c FROM sheep "
      "WHERE status NOT IN ('sold', 'dead')$fc "
      "GROUP BY breed ORDER BY c DESC",
    );
    return {for (final r in rows) r['breed'] as String: r['c'] as int};
  }

  Future<Map<String, int>> getFullStatusDistribution({int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? " WHERE farmId = $farmId" : "";
    final rows = await db.rawQuery(
      "SELECT status, COUNT(*) as c FROM sheep$fc GROUP BY status",
    );
    return {for (final r in rows) r['status'] as String: r['c'] as int};
  }

  Future<Map<String, int>> getGenderCounts({int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? " AND farmId = $farmId" : "";
    final f = await db.rawQuery(
      "SELECT COUNT(*) as c FROM sheep WHERE gender = 'female' AND status NOT IN ('sold', 'dead')$fc",
    );
    final m = await db.rawQuery(
      "SELECT COUNT(*) as c FROM sheep WHERE gender = 'male' AND status NOT IN ('sold', 'dead')$fc",
    );
    return {
      'female': Sqflite.firstIntValue(f) ?? 0,
      'male': Sqflite.firstIntValue(m) ?? 0,
    };
  }

  Future<String> buildCsvExport({int? farmId}) async {
    final sheep = await getAllSheep(farmId: farmId);
    final sb = StringBuffer();
    sb.writeln('Küpe No,İsim,Cinsiyet,Irk,Doğum Tarihi,Durum,Grup,Son Ağırlık (kg)');
    for (final s in sheep) {
      final birth = s.birthDate != null
          ? '${s.birthDate!.day}.${s.birthDate!.month}.${s.birthDate!.year}'
          : '';
      final gender = s.gender == 'female' ? 'Dişi' : 'Erkek';
      final status = _statusLabel(s.status);
      sb.writeln('"${s.earTag}","${s.name ?? ""}","$gender","${s.breed}","$birth","$status","${s.groupName ?? ""}","${s.lastWeight ?? ""}"');
    }
    return sb.toString();
  }

  String _statusLabel(String s) => switch (s) {
    'active' => 'Sağlıklı',
    'pregnant' => 'Gebe',
    'sick' => 'Hasta',
    'sold' => 'Satıldı',
    'dead' => 'Vefat',
    _ => s,
  };

  // --- Bulk vaccination ---
  Future<void> insertBulkVaccine({
    required List<int> sheepIds,
    required String vaccineName,
    required DateTime date,
    DateTime? nextDate,
  }) async {
    final db = await database;
    final batch = db.batch();
    for (final id in sheepIds) {
      batch.insert('health_records', {
        'sheepId': id,
        'type': 'vaccine',
        'name': vaccineName,
        'date': date.toIso8601String(),
        'nextDate': nextDate?.toIso8601String(),
        'status': 'done',
      });
    }
    await batch.commit(noResult: true);
  }

  // --- Financial transactions ---
  String _periodFilter(String period) {
    switch (period) {
      case 'month':
        return "AND strftime('%Y-%m', date) = strftime('%Y-%m', 'now')";
      case 'year':
        return "AND strftime('%Y', date) = strftime('%Y', 'now')";
      default:
        return '';
    }
  }

  Future<int> insertFinancialTransaction(FinancialTransaction t) async {
    final db = await database;
    int txId = 0;
    await db.transaction((txn) async {
      txId = await txn.insert('financial_transactions', {
        'farmId': t.farmId,
        'type': t.type,
        'category': t.category,
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'note': t.note,
        'buyerName': t.buyerName,
        'scope': t.scope,
        'createdAt': t.createdAt.toIso8601String(),
      });
      for (final sid in t.sheepIds) {
        await txn.insert('transaction_sheep', {'transactionId': txId, 'sheepId': sid});
      }
      if (t.category == 'animal_sale') {
        for (final sid in t.sheepIds) {
          await txn.update('sheep', {'status': 'sold'}, where: 'id = ?', whereArgs: [sid]);
        }
      }
    });
    return txId;
  }

  Future<Map<String, double>> getFinancialSummary({required String period, int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? "AND farmId = $farmId" : "";
    final pf = _periodFilter(period);
    final rows = await db.rawQuery(
      "SELECT type, SUM(amount) as total FROM financial_transactions WHERE 1=1 $fc $pf GROUP BY type",
    );
    double income = 0, expense = 0;
    for (final r in rows) {
      if (r['type'] == 'income') income = (r['total'] as num).toDouble();
      if (r['type'] == 'expense') expense = (r['total'] as num).toDouble();
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }

  Future<List<FinancialTransaction>> getRecentTransactions({int? farmId, int limit = 10}) async {
    final db = await database;
    final fc = farmId != null ? "WHERE farmId = $farmId" : "";
    final rows = await db.rawQuery(
      "SELECT * FROM financial_transactions $fc ORDER BY date DESC, id DESC LIMIT $limit",
    );
    return Future.wait(rows.map((r) async {
      final links = await db.query('transaction_sheep',
          where: 'transactionId = ?', whereArgs: [r['id']]);
      return _rowToTransaction(r, links.map((l) => l['sheepId'] as int).toList());
    }));
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrend({int? farmId, int months = 6}) async {
    final db = await database;
    final fc = farmId != null ? "AND farmId = $farmId" : "";
    final rows = await db.rawQuery(
      "SELECT strftime('%Y-%m', date) as m, "
      "SUM(CASE WHEN type='income' THEN amount ELSE 0 END) as income, "
      "SUM(CASE WHEN type='expense' THEN amount ELSE 0 END) as expense "
      "FROM financial_transactions "
      "WHERE date >= date('now', '-${months - 1} months', 'start of month') $fc "
      "GROUP BY m ORDER BY m",
    );
    return rows.map((r) => {
      'month': r['m'] as String,
      'income': (r['income'] as num?)?.toDouble() ?? 0.0,
      'expense': (r['expense'] as num?)?.toDouble() ?? 0.0,
    }).toList();
  }

  Future<Map<String, double>> getExpenseBreakdown({required String period, int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? "AND farmId = $farmId" : "";
    final pf = _periodFilter(period);
    final rows = await db.rawQuery(
      "SELECT category, SUM(amount) as total FROM financial_transactions "
      "WHERE type='expense' $fc $pf GROUP BY category ORDER BY total DESC",
    );
    return {for (final r in rows) r['category'] as String: (r['total'] as num).toDouble()};
  }

  Future<List<FinancialTransaction>> getAllTransactions({required String period, int? farmId}) async {
    final db = await database;
    final fc = farmId != null ? "AND farmId = $farmId" : "";
    final pf = _periodFilter(period);
    final rows = await db.rawQuery(
      "SELECT * FROM financial_transactions WHERE 1=1 $fc $pf ORDER BY date DESC, id DESC",
    );
    return Future.wait(rows.map((r) async {
      final links = await db.query('transaction_sheep',
          where: 'transactionId = ?', whereArgs: [r['id']]);
      return _rowToTransaction(r, links.map((l) => l['sheepId'] as int).toList());
    }));
  }

  FinancialTransaction _rowToTransaction(Map<String, Object?> r, List<int> sheepIds) =>
      FinancialTransaction(
        id: r['id'] as int?,
        farmId: r['farmId'] as int?,
        type: r['type'] as String,
        category: r['category'] as String,
        amount: (r['amount'] as num).toDouble(),
        date: DateTime.parse(r['date'] as String),
        note: r['note'] as String?,
        buyerName: r['buyerName'] as String?,
        scope: (r['scope'] as String?) ?? 'farm',
        sheepIds: sheepIds,
        createdAt: DateTime.parse(r['createdAt'] as String),
      );

  // --- Bootstrap demo data if sheep table empty ---
  Future<void> ensureDemoData() async {
    final db = await database;
    final countRes = await db.rawQuery('SELECT COUNT(*) as c FROM sheep');
    final c = Sqflite.firstIntValue(countRes) ?? 0;
    if (c > 0) return;

    final farmId = await insertFarm(const Farm(name: 'Ertuğrul Çiftliği'));

    for (final s in Sheep.demoList) {
      final id = await insertSheep(s.copyWith(farmId: farmId));
      if (s.id == 1) {
        for (final h in HealthRecord.demoList) {
          await insertHealthRecord(HealthRecord(
            sheepId: id,
            type: h.type,
            name: h.name,
            date: h.date,
            nextDate: h.nextDate,
            vetName: h.vetName,
            notes: h.notes,
            status: h.status,
          ));
        }
        for (final w in WeightRecord.demoList) {
          await insertWeightRecord(WeightRecord(
            sheepId: id,
            date: w.date,
            weightKg: w.weightKg,
            notes: w.notes,
          ));
        }
      }
    }
  }
}
