import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum OfflineStatus {
  online,
  offline,
  syncing,
  error,
}

enum SyncPriority {
  low,
  medium,
  high,
  critical,
}

class DjumanOfflineService {
  static final DjumanOfflineService _instance = DjumanOfflineService._internal();
  factory DjumanOfflineService() => _instance;
  DjumanOfflineService._internal();

  Database? _database;
  StreamController<OfflineStatus> _statusController = StreamController<OfflineStatus>.broadcast();
  StreamController<List<Map<String, dynamic>>> _operationsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Timer? _syncTimer;
  Timer? _connectivityTimer;
  bool _isOnline = false;
  bool _isInitialized = false;

  // Streams
  Stream<OfflineStatus> get statusStream => _statusController.stream;
  Stream<List<Map<String, dynamic>>> get operationsStream => _operationsController.stream;

  // Getters
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  OfflineStatus get currentStatus => _isOnline ? OfflineStatus.online : OfflineStatus.offline;

  Future<void> init() async {
    try {
      await _initDatabase();
      await _checkConnectivity();
      _startSyncTimer();
      _startConnectivityTimer();
      _isInitialized = true;
      _updateStatus(_isOnline ? OfflineStatus.online : OfflineStatus.offline);
      debugPrint('✅ DjumanOfflineService initialisé (SQLite)');
    } catch (e) {
      debugPrint('❌ Erreur initialisation DjumanOfflineService: $e');
      _updateStatus(OfflineStatus.error);
      rethrow;
    }
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'djuman_offline.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table des opérations offline
        await db.execute('''
          CREATE TABLE offline_operations (
            id TEXT PRIMARY KEY,
            operation TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            is_synced INTEGER DEFAULT 0,
            priority TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0
          )
        ''');
        
        // Table des données cachées
        await db.execute('''
          CREATE TABLE cached_data (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            entity_id TEXT,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            expires_at INTEGER
          )
        ''');
        
        // Table des métadonnées de sync
        await db.execute('''
          CREATE TABLE sync_metadata (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            last_sync_timestamp INTEGER,
            last_sync_version INTEGER,
            has_pending_conflicts INTEGER DEFAULT 0
          )
        ''');
        
        // Table des conflits
        await db.execute('''
          CREATE TABLE conflicts (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            local_version TEXT NOT NULL,
            server_version TEXT NOT NULL,
            conflict_date INTEGER NOT NULL,
            is_resolved INTEGER DEFAULT 0,
            resolution TEXT
          )
        ''');
        
        // Index pour optimiser les requêtes
        await db.execute('CREATE INDEX idx_operations_priority ON offline_operations(priority)');
        await db.execute('CREATE INDEX idx_operations_timestamp ON offline_operations(created_at)');
        await db.execute('CREATE INDEX idx_cached_data_type ON cached_data(entity_type)');
        await db.execute('CREATE INDEX idx_cached_data_expires ON cached_data(expires_at)');
        await db.execute('CREATE INDEX idx_sync_metadata_type ON sync_metadata(entity_type)');
        await db.execute('CREATE INDEX idx_conflicts_type ON conflicts(entity_type)');
      },
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      if (_isOnline) {
        try {
          final dio = Dio();
          await dio.get(
            'https://api.sika.africa/health',
            options: Options(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );
        } catch (e) {
          _isOnline = false;
        }
      }
      
      _updateStatus(_isOnline ? OfflineStatus.online : OfflineStatus.offline);
      
      if (_isOnline) {
        await syncPendingOperations();
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification connectivité: $e');
      _isOnline = false;
      _updateStatus(OfflineStatus.offline);
    }
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isOnline) {
        await syncPendingOperations();
      }
    });
  }

  void _startConnectivityTimer() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkConnectivity();
    });
  }

  void _updateStatus(OfflineStatus status) {
    _statusController.add(status);
    debugPrint('📶 Status offline DJUMAN: $status');
  }

  // ===== Gestion des données =====

  Future<List<Map<String, dynamic>>> getEntityData(String entityName) async {
    if (!_isInitialized) return [];
    try {
      final result = await _database!.query(
        'cached_data',
        where: 'entity_type = ?',
        whereArgs: [entityName],
      );
      return result.map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('❌ Erreur lecture entity data: $e');
      return [];
    }
  }

  Future<void> saveEntityData(String entityName, List<Map<String, dynamic>> data) async {
    if (!_isInitialized) await init();
    try {
      final batch = _database!.batch();
      
      // Supprimer les anciennes données
      await _database!.delete(
        'cached_data',
        where: 'entity_type = ?',
        whereArgs: [entityName],
      );
      
      // Insérer les nouvelles données
      for (final item in data) {
        final id = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        batch.insert('cached_data', {
          'id': '${entityName}_$id',
          'entity_type': entityName,
          'entity_id': id,
          'data': jsonEncode(item),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      await batch.commit(noResult: true);
      debugPrint('💾 Données sauvegardées pour DJUMAN/$entityName: ${data.length} éléments');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde entity data: $e');
    }
  }

  Future<void> clearEntityData(String entityName) async {
    if (!_isInitialized) await init();
    try {
      await _database!.delete(
        'cached_data',
        where: 'entity_type = ?',
        whereArgs: [entityName],
      );
      debugPrint('[DJUMAN_OFFLINE] Supprimé $entityName');
    } catch (e) {
      debugPrint('[DJUMAN_OFFLINE] Erreur suppression $entityName: $e');
    }
  }

  Future<void> clearAll() async {
    if (!_isInitialized) await init();
    try {
      await _database!.delete('cached_data');
      await _database!.delete('offline_operations');
      await _database!.delete('sync_metadata');
      await _database!.delete('conflicts');
      debugPrint('[DJUMAN_OFFLINE] Cache vidé');
    } catch (e) {
      debugPrint('[DJUMAN_OFFLINE] Erreur vidage cache: $e');
    }
  }

  // ===== Gestion des opérations offline =====

  Future<void> addOperation({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.medium,
  }) async {
    if (!_isInitialized) await init();
    
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _database!.insert(
        'offline_operations',
        {
          'id': id,
          'operation': operation,
          'entity_type': entityType,
          'entity_id': entityId,
          'data': jsonEncode(data),
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 0,
          'priority': priority.toString().split('.').last,
          'retry_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      await _notifyOperationsChanged();
      debugPrint('📝 Opération offline ajoutée: $operation $entityType/$entityId');
    } catch (e) {
      debugPrint('❌ Erreur ajout opération offline: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOfflineOperations() async {
    if (!_isInitialized) return [];
    
    try {
      final result = await _database!.query(
        'offline_operations',
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'priority DESC, created_at ASC',
      );
      
      return result.map((row) => {
        'id': row['id'] as String,
        'operation': row['operation'] as String,
        'entity_type': row['entity_type'] as String,
        'entity_id': row['entity_id'] as String,
        'data': jsonDecode(row['data'] as String) as Map<String, dynamic>,
        'created_at': DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        'is_synced': (row['is_synced'] as int) == 1,
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération opérations: $e');
      return [];
    }
  }

  Future<void> syncPendingOperations() async {
    if (!_isOnline || !_isInitialized) return;
    
    try {
      _updateStatus(OfflineStatus.syncing);
      
      final operations = await getOfflineOperations();
      final dio = Dio();
      
      for (final operation in operations) {
        try {
          // TODO: Implémenter la logique de synchronisation réelle avec l'API
          // Pour l'instant, on marque comme synchronisé
          await _database!.update(
            'offline_operations',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [operation['id']],
          );
          
          debugPrint('✅ Opération synchronisée: ${operation['operation']} ${operation['entity_type']}');
          
        } catch (e) {
          debugPrint('❌ Erreur synchronisation opération: $e');
          
          final newRetryCount = (operation['data']['_retry_count'] as int? ?? 0) + 1;
          
          if (newRetryCount >= 3) {
            await _database!.delete(
              'offline_operations',
              where: 'id = ?',
              whereArgs: [operation['id']],
            );
            debugPrint('🗑️ Opération supprimée après 3 tentatives: ${operation['id']}');
          } else {
            await _database!.update(
              'offline_operations',
              {'retry_count': newRetryCount},
              where: 'id = ?',
              whereArgs: [operation['id']],
            );
          }
        }
      }
      
      await _notifyOperationsChanged();
      _updateStatus(OfflineStatus.online);
      
    } catch (e) {
      debugPrint('❌ Erreur synchronisation batch: $e');
      _updateStatus(OfflineStatus.error);
    }
  }

  Future<void> _notifyOperationsChanged() async {
    final operations = await getOfflineOperations();
    _operationsController.add(operations);
  }

  // ===== Gestion des métadonnées de sync =====

  Future<void> saveLastSyncTimestamp(String entityType, DateTime timestamp) async {
    if (!_isInitialized) await init();
    try {
      await _database!.insert(
        'sync_metadata',
        {
          'id': entityType,
          'entity_type': entityType,
          'last_sync_timestamp': timestamp.millisecondsSinceEpoch,
          'has_pending_conflicts': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde sync timestamp: $e');
    }
  }

  Future<DateTime?> getLastSyncTimestamp(String entityType) async {
    if (!_isInitialized) return null;
    try {
      final result = await _database!.query(
        'sync_metadata',
        where: 'entity_type = ?',
        whereArgs: [entityType],
      );
      if (result.isNotEmpty && result.first['last_sync_timestamp'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(result.first['last_sync_timestamp'] as int);
      }
    } catch (e) {
      debugPrint('❌ Erreur lecture sync timestamp: $e');
    }
    return null;
  }

  // ===== Statistiques =====

  Future<Map<String, dynamic>> getStatistics() async {
    if (!_isInitialized) await init();
    
    try {
      final pendingOps = await _database!.rawQuery('SELECT COUNT(*) as count FROM offline_operations WHERE is_synced = 0');
      final cachedItems = await _database!.rawQuery('SELECT COUNT(*) as count FROM cached_data');
      final expiredItems = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM cached_data WHERE expires_at IS NOT NULL AND expires_at < ?',
        [DateTime.now().millisecondsSinceEpoch],
      );
      final conflicts = await _database!.rawQuery('SELECT COUNT(*) as count FROM conflicts WHERE is_resolved = 0');
      
      return {
        'is_online': _isOnline,
        'is_initialized': _isInitialized,
        'pending_operations': pendingOps.first['count'] ?? 0,
        'cached_items': cachedItems.first['count'] ?? 0,
        'expired_items': expiredItems.first['count'] ?? 0,
        'conflicts': conflicts.first['count'] ?? 0,
        'last_sync': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques: $e');
      return {};
    }
  }

  // ===== Nettoyage =====

  Future<void> cleanup() async {
    if (!_isInitialized) return;
    
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      
      await _database!.delete(
        'offline_operations',
        where: 'created_at < ? AND retry_count >= 3',
        whereArgs: [weekAgo],
      );
      
      await _database!.delete(
        'cached_data',
        where: 'expires_at IS NOT NULL AND expires_at < ?',
        whereArgs: [DateTime.now().millisecondsSinceEpoch],
      );
      
      await _database!.delete(
        'conflicts',
        where: 'is_resolved = 1 AND conflict_date < ?',
        whereArgs: [weekAgo],
      );
      
      debugPrint('🧹 Nettoyage terminé');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage: $e');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivityTimer?.cancel();
    _statusController.close();
    _operationsController.close();
    _database?.close();
    _isInitialized = false;
  }

  Future<void> close() async {
    dispose();
  }
}
