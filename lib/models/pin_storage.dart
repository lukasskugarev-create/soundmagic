import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/sound_pin.dart';

class PinStorage {
  static const _fileName = 'sound_pins.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<SoundPin>> loadPins() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => SoundPin.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePins(List<SoundPin> pins) async {
    final file = await _getFile();
    final data = jsonEncode(pins.map((p) => p.toJson()).toList());
    await file.writeAsString(data);
  }

  static Future<void> addPin(SoundPin pin) async {
    final pins = await loadPins();
    pins.add(pin);
    await savePins(pins);
  }

  static Future<void> deletePin(String id) async {
    final pins = await loadPins();
    final pin = pins.firstWhere((p) => p.id == id);
    // Delete audio file
    final audioFile = File(pin.filePath);
    if (await audioFile.exists()) await audioFile.delete();
    pins.removeWhere((p) => p.id == id);
    await savePins(pins);
  }
}
