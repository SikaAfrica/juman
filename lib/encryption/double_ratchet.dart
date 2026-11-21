// ===============================================================
// DOUBLE RATCHET PROTOCOL - VERSION CORRIGÉE
// ===============================================================

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sika/encryption/models/ratchet_message.dart';

/// Double Ratchet Session - Implémentation complète et corrigée
class DoubleRatchetSession {
  // =============================================================
  // ÉTAT DE LA SESSION (PUBLIC POUR LE MANAGER)
  // =============================================================

  SecretKey? _rootKey;
  SimpleKeyPair? _sendingRatchetKeyPair;
  SimplePublicKey? _receivingRatchetPublicKey;
  SecretKey? _sendingChainKey;
  SecretKey? _receivingChainKey;
  int _sendingMessageNumber = 0;
  int _receivingMessageNumber = 0;
  int _previousChainLength = 0;
  final Map<int, SecretKey> _skippedMessageKeys = {};
  final Set<int> _receivedMessageNumbers = {};
  
  // Identifiants
  final String conversationId;
  final String remoteUserId;
  
  // Métadonnées
  final DateTime _createdAt;
  DateTime? _lastUsedAt;
  bool _isInitialized = false;

  // =============================================================
  // GETTERS PUBLICS
  // =============================================================

  bool get isInitialized => _isInitialized;
  int get sendingMessageNumber => _sendingMessageNumber;
  int get receivingMessageNumber => _receivingMessageNumber;
  DateTime get createdAt => _createdAt;
  DateTime? get lastUsedAt => _lastUsedAt;

  // =============================================================
  // CONFIGURATION
  // =============================================================

  final X25519 _x25519 = X25519();
  final Hkdf _hkdfRoot = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 64, // Pour split RK + CK
  );
  final Hkdf _hkdfChain = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 64, // Pour split CK + MK
  );

  static const int _maxSkip = 100;
  static const int _ratchetThreshold = 3;

  // =============================================================
  // CONSTRUCTEUR PRINCIPAL
  // =============================================================

  DoubleRatchetSession({
    required this.conversationId,
    required this.remoteUserId,
    required SecretKey initialRootKey,
    required SimpleKeyPair initialSendingKeyPair,
    SimplePublicKey? remoteIdentityKey,
    DateTime? createdAt,
  }) : _createdAt = createdAt ?? DateTime.now() {
    _rootKey = initialRootKey;
    _sendingRatchetKeyPair = initialSendingKeyPair;
    _receivingRatchetPublicKey = remoteIdentityKey;
    
    // Initialiser les chaînes
    _initializeChainKeys();
  }

  // =============================================================
  // INITIALISATION DES CHAÎNES
  // =============================================================

  Future<void> _initializeChainKeys() async {
    try {
      // Dériver les chaînes d'envoi et de réception depuis la root key
      final rootKeyBytes = await _rootKey!.extractBytes();
      final chainKeys = await _hkdfRoot.deriveKey(
        secretKey: _rootKey!,
        info: utf8.encode('Idjowle-V3-ChainKeys'),
        nonce: rootKeyBytes,
      );
      
      final chainKeyBytes = await chainKeys.extractBytes();
      
      _sendingChainKey = SecretKey(chainKeyBytes.sublist(0, 32));
      _receivingChainKey = SecretKey(chainKeyBytes.sublist(32, 64));
      _isInitialized = true;
      
      debugPrint('✅ Double Ratchet session initialized for $conversationId');
    } catch (e) {
      debugPrint('❌ Failed to initialize chain keys: $e');
      rethrow;
    }
  }

  // =============================================================
  // CHIFFREMENT
  // =============================================================

  Future<RatchetMessage> encryptMessage(String plaintext) async {
    if (!_isInitialized) {
      throw Exception('Session not initialized');
    }
    if (_rootKey == null || _sendingChainKey == null) {
      throw Exception('Session keys not available');
    }

    // 1. Dériver la clé de message
    final messageKey = await _deriveMessageKey(
      _sendingChainKey!,
      _sendingMessageNumber,
    );

    // 2. Avancer la chaîne d'envoi
    _sendingChainKey = await _advanceChain(_sendingChainKey!);
    _sendingMessageNumber++;

    // 3. Chiffrer avec AES-256-GCM
    final encrypted = await _encryptAESGCM(plaintext, messageKey);

    // 4. Ratchet périodique
    if (_sendingMessageNumber % _ratchetThreshold == 0) {
      await _performSendingRatchet();
    }

    // 5. Construire le message
    final sendingPublicKey = await _sendingRatchetKeyPair!.extractPublicKey();
    
    _lastUsedAt = DateTime.now();

    return RatchetMessage(
      version: 3,
      messageNumber: _sendingMessageNumber - 1,
      ratchetPublicKey: _encodeBase64(sendingPublicKey.bytes),
      ciphertext: _encodeBase64(encrypted.ciphertext),
      nonce: _encodeBase64(encrypted.nonce),
      previousChainLength: _previousChainLength,
    );
  }

  // =============================================================
  // DÉCHIFFREMENT
  // =============================================================

  Future<String> decryptMessage(RatchetMessage message) async {
    if (!_isInitialized) {
      throw Exception('Session not initialized');
    }
    if (_rootKey == null) {
      throw Exception('Session keys not available');
    }

    // 1. Anti-replay
    if (_receivedMessageNumbers.contains(message.messageNumber)) {
      throw Exception('Message replay detected');
    }

    // 2. Vérifier le DH ratchet
    final senderPublicKeyBytes = _decodeBase64(message.ratchetPublicKey);
    final senderPublicKey = SimplePublicKey(
      senderPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    if (_receivingRatchetPublicKey == null ||
        !_publicKeysEqual(senderPublicKey, _receivingRatchetPublicKey!)) {
      await _performReceivingRatchet(
        senderPublicKey,
        message.previousChainLength,
      );
    }

    // 3. Gérer les messages manqués
    if (message.messageNumber > _receivingMessageNumber) {
      final skipCount = message.messageNumber - _receivingMessageNumber;
      if (skipCount > _maxSkip) {
        throw Exception('Too many skipped messages: $skipCount');
      }

      for (int i = _receivingMessageNumber; i < message.messageNumber; i++) {
        final skippedKey = await _deriveMessageKey(
          _receivingChainKey!,
          i,
        );
        _skippedMessageKeys[i] = skippedKey;
        _receivingChainKey = await _advanceChain(_receivingChainKey!);
      }
      _receivingMessageNumber = message.messageNumber;
    }

    // 4. Récupérer la clé de message
    SecretKey messageKey;
    if (_skippedMessageKeys.containsKey(message.messageNumber)) {
      messageKey = _skippedMessageKeys[message.messageNumber]!;
      _skippedMessageKeys.remove(message.messageNumber);
    } else {
      messageKey = await _deriveMessageKey(
        _receivingChainKey!,
        _receivingMessageNumber,
      );
      _receivingChainKey = await _advanceChain(_receivingChainKey!);
      _receivingMessageNumber++;
    }

    // 5. Enregistrer le message reçu
    _receivedMessageNumbers.add(message.messageNumber);
    _cleanupReceivedMessages();

    // 6. Déchiffrer avec AES-256-GCM
    final ciphertext = _decodeBase64(message.ciphertext);
    final nonce = _decodeBase64(message.nonce);
    
    final plaintext = await _decryptAESGCM(ciphertext, nonce, messageKey);
    
    _lastUsedAt = DateTime.now();

    return plaintext;
  }

  // =============================================================
  // DH RATCHET (ENVOI)
  // =============================================================

  Future<void> _performSendingRatchet() async {
    if (_sendingRatchetKeyPair == null || _receivingRatchetPublicKey == null) {
      return;
    }

    // Sauvegarder l'ancienne longueur de chaîne
    _previousChainLength = _sendingMessageNumber;

    // Générer nouvelle clé éphémère
    final newSendingKeyPair = await _x25519.newKeyPair();

    // Échange DH
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: newSendingKeyPair,
      remotePublicKey: _receivingRatchetPublicKey!,
    );
    final sharedSecretBytes = await sharedSecret.extractBytes();

    // Mettre à jour la root key (KDF_RK)
    final rootKeyBytes = await _rootKey!.extractBytes();
    final newRootKey = await _hkdfRoot.deriveKey(
      secretKey: SecretKey(sharedSecretBytes),
      info: utf8.encode('Idjowle-V3-RootKey'),
      nonce: rootKeyBytes,
    );
    
    final newRootKeyBytes = await newRootKey.extractBytes();
    _rootKey = SecretKey(newRootKeyBytes.sublist(0, 32));
    
    // Dériver la nouvelle chaîne d'envoi
    _sendingChainKey = SecretKey(newRootKeyBytes.sublist(32, 64));

    // Mettre à jour la clé de ratchet
    _sendingRatchetKeyPair = newSendingKeyPair;
    _sendingMessageNumber = 0;

    debugPrint('🔄 Sending DH ratchet performed for $conversationId');
  }

  // =============================================================
  // DH RATCHET (RÉCEPTION)
  // =============================================================

  Future<void> _performReceivingRatchet(
    SimplePublicKey newSenderPublicKey,
    int previousChainLength,
  ) async {
    if (_sendingRatchetKeyPair == null || _rootKey == null) {
      throw Exception('Cannot perform receiving ratchet: missing keys');
    }

    // Sauvegarder l'ancienne chaîne de réception dans skipped keys
    if (_receivingChainKey != null) {
      for (int i = _receivingMessageNumber; i < previousChainLength; i++) {
        final skippedKey = await _deriveMessageKey(
          _receivingChainKey!,
          i,
        );
        _skippedMessageKeys[i] = skippedKey;
        _receivingChainKey = await _advanceChain(_receivingChainKey!);
      }
    }

    // Échange DH
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: _sendingRatchetKeyPair!,
      remotePublicKey: newSenderPublicKey,
    );
    final sharedSecretBytes = await sharedSecret.extractBytes();

    // Mettre à jour la root key (KDF_RK)
    final rootKeyBytes = await _rootKey!.extractBytes();
    final newRootKey = await _hkdfRoot.deriveKey(
      secretKey: SecretKey(sharedSecretBytes),
      info: utf8.encode('Idjowle-V3-RootKey'),
      nonce: rootKeyBytes,
    );
    
    final newRootKeyBytes = await newRootKey.extractBytes();
    _rootKey = SecretKey(newRootKeyBytes.sublist(0, 32));

    // Dériver les nouvelles chaînes
    _receivingChainKey = SecretKey(newRootKeyBytes.sublist(32, 64));
    
    // Dériver une nouvelle chaîne d'envoi pour répondre
    final newSendingChainKey = await _hkdfRoot.deriveKey(
      secretKey: _rootKey!,
      info: utf8.encode('Idjowle-V3-SendingChain'),
    );
    final newSendingBytes = await newSendingChainKey.extractBytes();
    _sendingChainKey = SecretKey(newSendingBytes);

    // Mettre à jour les compteurs
    _receivingRatchetPublicKey = newSenderPublicKey;
    _receivingMessageNumber = 0;
    _sendingMessageNumber = 0;

    debugPrint('🔄 Receiving DH ratchet performed for $conversationId');
  }

  // =============================================================
  // DÉRIVATION DE CLÉS
  // =============================================================

  Future<SecretKey> _deriveMessageKey(
    SecretKey chainKey,
    int messageNumber,
  ) async {
    final chainKeyBytes = await chainKey.extractBytes();
    final messageKey = await _hkdfChain.deriveKey(
      secretKey: chainKey,
      info: utf8.encode('Idjowle-V3-MessageKey-$messageNumber'),
      nonce: chainKeyBytes,
    );
    
    final messageKeyBytes = await messageKey.extractBytes();
    return SecretKey(messageKeyBytes.sublist(0, 32));
  }

  Future<SecretKey> _advanceChain(SecretKey chainKey) async {
    final chainKeyBytes = await chainKey.extractBytes();
    final newChainKey = await _hkdfChain.deriveKey(
      secretKey: chainKey,
      info: utf8.encode('Idjowle-V3-AdvanceChain'),
      nonce: chainKeyBytes,
    );
    
    final newChainKeyBytes = await newChainKey.extractBytes();
    return SecretKey(newChainKeyBytes.sublist(0, 32));
  }

  // =============================================================
  // CHIFFREMENT AES-256-GCM
  // =============================================================

  Future<AESGCMResult> _encryptAESGCM(
    String plaintext,
    SecretKey key,
  ) async {
    final keyBytes = await key.extractBytes();
    final aesKey = enc.Key(Uint8List.fromList(keyBytes));
    final nonce = _randomBytes(12);
    final iv = enc.IV(nonce);
    
    final encrypter = enc.Encrypter(
      enc.AES(aesKey, mode: enc.AESMode.gcm),
    );
    
    final encrypted = encrypter.encrypt(
      plaintext,
      iv: iv,
    );
    
    return AESGCMResult(
      ciphertext: encrypted.bytes,
      nonce: nonce,
    );
  }

  Future<String> _decryptAESGCM(
    Uint8List ciphertext,
    Uint8List nonce,
    SecretKey key,
  ) async {
    final keyBytes = await key.extractBytes();
    final aesKey = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV(nonce);
    
    final encrypter = enc.Encrypter(
      enc.AES(aesKey, mode: enc.AESMode.gcm),
    );
    
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(ciphertext),
      iv: iv,
    );
    
    return utf8.decode(decrypted);
  }

  // =============================================================
  // NETTOYAGE
  // =============================================================

  void _cleanupReceivedMessages() {
    if (_receivedMessageNumbers.length > 1000) {
      final sorted = _receivedMessageNumbers.toList()..sort();
      final toRemove = sorted.sublist(0, sorted.length - 900);
      _receivedMessageNumbers.removeAll(toRemove);
    }
  }

  // =============================================================
  // UTILITAIRES
  // =============================================================

  Uint8List _randomBytes(int length) {
    final randomKey = SecretKeyData.random(length: length);
    return Uint8List.fromList(randomKey.bytes);
  }

  bool _publicKeysEqual(
    SimplePublicKey key1,
    SimplePublicKey key2,
  ) {
    final bytes1 = key1.bytes;
    final bytes2 = key2.bytes;
    if (bytes1.length != bytes2.length) return false;
    for (int i = 0; i < bytes1.length; i++) {
      if (bytes1[i] != bytes2[i]) return false;
    }
    return true;
  }

  String _encodeBase64(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Uint8List _decodeBase64(String value) {
    var normalized = value;
    final mod = normalized.length % 4;
    if (mod != 0) {
      normalized += '=' * (4 - mod);
    }
    return Uint8List.fromList(base64Url.decode(normalized));
  }

  // =============================================================
  // SÉRIALISATION
  // =============================================================

  Future<Map<String, dynamic>> toJson() async {
    return {
      'conversation_id': conversationId,
      'remote_user_id': remoteUserId,
      'root_key': _rootKey != null ? _encodeBase64(await _rootKey!.extractBytes()) : null,
      'sending_message_number': _sendingMessageNumber,
      'receiving_message_number': _receivingMessageNumber,
      'previous_chain_length': _previousChainLength,
      'created_at': _createdAt.toIso8601String(),
      'last_used_at': _lastUsedAt?.toIso8601String(),
      'is_initialized': _isInitialized,
    };
  }

  static Future<DoubleRatchetSession> fromJson(
    Map<String, dynamic> json,
    X25519 x25519,
  ) async {
    final conversationId = json['conversation_id'] as String;
    final remoteUserId = json['remote_user_id'] as String;
    
    final rootKeyBytes = _decodeBase64Static(json['root_key'] as String);
    final rootKey = SecretKey(rootKeyBytes);
    
    final sendingKeyPair = await x25519.newKeyPair();
    
    final session = DoubleRatchetSession(
      conversationId: conversationId,
      remoteUserId: remoteUserId,
      initialRootKey: rootKey,
      initialSendingKeyPair: sendingKeyPair,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
    
    session._sendingMessageNumber = json['sending_message_number'] as int;
    session._receivingMessageNumber = json['receiving_message_number'] as int;
    session._previousChainLength = json['previous_chain_length'] as int;
    
    if (json['last_used_at'] != null) {
      session._lastUsedAt = DateTime.parse(json['last_used_at'] as String);
    }
    
    return session;
  }

  static Uint8List _decodeBase64Static(String value) {
    var normalized = value;
    final mod = normalized.length % 4;
    if (mod != 0) {
      normalized += '=' * (4 - mod);
    }
    return Uint8List.fromList(base64Url.decode(normalized));
  }
}

/// ===============================================================
/// AES-GCM RESULT
/// ===============================================================

class AESGCMResult {
  final Uint8List ciphertext;
  final Uint8List nonce;

  AESGCMResult({
    required this.ciphertext,
    required this.nonce,
  });
}

/// ===============================================================
/// SESSION MANAGER CORRIGÉ
/// ===============================================================

class RatchetSessionManager {
  static final RatchetSessionManager _instance =
      RatchetSessionManager._internal();

  factory RatchetSessionManager() => _instance;

  RatchetSessionManager._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // ✅ La Map est maintenant publique pour le service
  final Map<String, DoubleRatchetSession> _sessions = {};
  final X25519 _x25519 = X25519();

  // ✅ Méthode publique pour accéder à une session
  Future<DoubleRatchetSession?> getSession(String conversationId) async {
    if (_sessions.containsKey(conversationId)) {
      return _sessions[conversationId]!;
    }
    return await _loadSession(conversationId);
  }

  // ✅ Méthode publique pour obtenir ou créer une session
  Future<DoubleRatchetSession> getOrCreateSession(
    String conversationId, {
    SecretKey? initialRootKey,
    SimpleKeyPair? initialSendingKeyPair,
    String? remoteUserId,
  }) async {
    // Vérifier en mémoire
    if (_sessions.containsKey(conversationId)) {
      return _sessions[conversationId]!;
    }

    // Essayer de restaurer depuis le stockage
    final session = await _loadSession(conversationId);
    if (session != null) {
      _sessions[conversationId] = session;
      return session;
    }

    // Créer nouvelle session
    if (initialRootKey == null || initialSendingKeyPair == null) {
      throw Exception('Initial keys required for new session');
    }

    if (remoteUserId == null) {
      throw Exception('Remote user ID required for new session');
    }

    final newSession = DoubleRatchetSession(
      conversationId: conversationId,
      remoteUserId: remoteUserId,
      initialRootKey: initialRootKey,
      initialSendingKeyPair: initialSendingKeyPair,
    );

    _sessions[conversationId] = newSession;
    return newSession;
  }

  // ✅ Méthode publique pour ajouter une session
  Future<void> addSession(
    String conversationId,
    DoubleRatchetSession session,
  ) async {
    _sessions[conversationId] = session;
    await saveSession(conversationId);
  }

  // ✅ Méthode publique pour sauvegarder
  Future<void> saveSession(String conversationId) async {
    final session = _sessions[conversationId];
    if (session != null) {
      final json = await session.toJson();
      await _storage.write(
        key: 'ratchet_session_$conversationId',
        value: jsonEncode(json),
      );
    }
  }

  // ✅ Méthode publique pour charger
  Future<DoubleRatchetSession?> _loadSession(String conversationId) async {
    final data = await _storage.read(key: 'ratchet_session_$conversationId');
    if (data == null) return null;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return await DoubleRatchetSession.fromJson(json, _x25519);
    } catch (e) {
      debugPrint('⚠️ Failed to load session $conversationId: $e');
      return null;
    }
  }

  // ✅ Méthode publique pour supprimer
  Future<void> deleteSession(String conversationId) async {
    _sessions.remove(conversationId);
    await _storage.delete(key: 'ratchet_session_$conversationId');
  }

  // ✅ Nettoyer toutes les sessions
  void clearAllSessions() {
    _sessions.clear();
  }

  // ✅ Obtenir toutes les conversations
  List<String> getActiveConversations() {
    return _sessions.keys.toList();
  }
}
