import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/add_child_display_mode.dart';

class ParentPreferencesProvider with ChangeNotifier {
  static const _addChildModeKey = 'parent_add_child_display_mode';

  AddChildDisplayMode _addChildDisplayMode = AddChildDisplayMode.inline;
  bool _isLoaded = false;

  AddChildDisplayMode get addChildDisplayMode => _addChildDisplayMode;
  bool get isLoaded => _isLoaded;

  ParentPreferencesProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _addChildDisplayMode =
          AddChildDisplayMode.fromId(prefs.getString(_addChildModeKey));
    } catch (e) {
      debugPrint('ParentPreferences load error: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setAddChildDisplayMode(AddChildDisplayMode mode) async {
    if (_addChildDisplayMode == mode) return;

    _addChildDisplayMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_addChildModeKey, mode.id);
    } catch (e) {
      debugPrint('ParentPreferences save error: $e');
    }
  }
}
