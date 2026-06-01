import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_helper.dart';

class FarmManager extends ChangeNotifier {
  FarmManager._();
  static final FarmManager instance = FarmManager._();

  Farm? _activeFarm;
  List<Farm> _farms = [];

  Farm? get activeFarm => _activeFarm;
  List<Farm> get farms => List.unmodifiable(_farms);
  int? get activeFarmId => _activeFarm?.id;

  Future<void> init() async {
    _farms = await DatabaseHelper.instance.getAllFarms();
    _activeFarm = _farms.isNotEmpty ? _farms.first : null;
    notifyListeners();
  }

  void switchFarm(Farm farm) {
    _activeFarm = farm;
    notifyListeners();
  }

  Future<Farm> createFarm(String name, {String? location}) async {
    final id = await DatabaseHelper.instance.insertFarm(Farm(name: name, location: location));
    final farm = Farm(id: id, name: name, location: location);
    _farms = [..._farms, farm];
    notifyListeners();
    return farm;
  }

  Future<void> renameFarm(int farmId, String name) async {
    await DatabaseHelper.instance.renameFarm(farmId, name);
    _farms = _farms.map((f) => f.id == farmId ? Farm(id: f.id, name: name, location: f.location) : f).toList();
    if (_activeFarm?.id == farmId) {
      _activeFarm = Farm(id: _activeFarm!.id, name: name, location: _activeFarm!.location);
    }
    notifyListeners();
  }
}
