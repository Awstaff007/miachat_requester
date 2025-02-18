// ***** 5. lib/utils/response_cache.dart *****

import 'dart:io';
import 'dart:convert'; // Importa la libreria JSON
import 'package:path_provider/path_provider.dart';

class ResponseCache {
  static const _cacheFileName = 'response_cache.json';
  static const _maxCacheSize = 50;

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<void> cacheResponse(Map<String, dynamic> response) async {
    final cache = await getCachedResponses();
    
    // LRU Cache Management
    if (cache.length >= _maxCacheSize) {
      cache.removeLast();
    }
    
    // Aggiorna timestamp
    response['_cached_at'] = DateTime.now().millisecondsSinceEpoch;
    
    cache.insert(0, response);
    await _saveCache(cache);
  }

  Future<void> _saveCache(List<Map<String, dynamic>> cache) async {
    final file = await _cacheFile;
    await file.writeAsString(jsonEncode(cache));
  }

  Future<List<Map<String, dynamic>>> getCachedResponses() async {
    try {
      final file = await _cacheFile;
      return List<Map<String, dynamic>>.from(jsonDecode(await file.readAsString()));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSortedResponses() async {
    final cache = await getCachedResponses();
    cache.sort((a, b) => b['_cached_at'].compareTo(a['_cached_at']));
    return cache;
  }
}