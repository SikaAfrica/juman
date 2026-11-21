import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:djuman/encryption/x3dh_protocol.dart';
import 'package:djuman/encryption/double_ratchet.dart';
import 'package:djuman/encryption/models/ratchet_message.dart';

/// ===============================================================
/// IDJOWLÊ - MESSAGE ENCRYPTION SERVICE V2
/// ===============================================================
///
/// Architecture:
///
/// Identity key:
///     X25519 private/public
///
/// Pour chaque message:
///
///     Ephemeral private key
///              │
///              │ ECDH
///              ▼
///     Recipient public key
///              │
///              ▼
///        Shared Secret
///              │
///              ▼
///        HKDF-SHA256
///              │
///              ▼
///        AES-256-GCM
///              │
///              ▼
///          Ciphertext
///
/// La clé privée d'identité reste dans le téléphone.
///
/// La clé privée éphémère est créée pour chaque message
/// et n'est jamais envoyée au serveur.
///
/// FastAPI ne reçoit que:
///
/// - public_key
/// - ephemeral_public_key
/// - nonce
/// - ciphertext
///
/// MongoDB ne reçoit jamais de clé privée.
/// ===============================================================

class MessageEncryptionService {
  static final MessageEncryptionService _instance =
      MessageEncryptionService._internal();

  factory MessageEncryptionService() => _instance;

  MessageEncryptionService._internal();

  // =============================================================
  // CRYPTOGRAPHIE
  // =============================================================

  final X25519 _x25519 = X25519();

  final Hkdf _hkdf = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  );

  final Sha256 _sha256 = Sha256();

  // =============================================================
  // X3DH & DOUBLE RATCHET
  // =============================================================

  final X3DHProtocol _x3dh = X3DHProtocol();

  final RatchetSessionManager _ratchetManager =
      RatchetSessionManager();

  // =============================================================
  // SECURE STORAGE
  // =============================================================

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _privateKeyStorage =
      'idjowle_e2e_identity_private_key_v2';

  static const String _publicKeyStorage =
      'idjowle_e2e_identity_public_key_v2';

  static const String _keyVersionStorage =
      'idjowle_e2e_key_version_v2';

  // =============================================================
  // API
  // =============================================================

  String? _apiBaseUrl;

  String? _authToken;

  // =============================================================
  // IDENTITÉ
  // =============================================================

  SimpleKeyPair? _identityKeyPair;

  String? _myPublicKeyB64;
  
  String? _myUserId;

  int _keyVersion = 1;

  bool _initialized = false;

  // =============================================================
  // CACHE DES CLÉS PUBLIQUES
  // =============================================================

  final Map<String, String> _publicKeyCache = {};

  final Map<String, int> _publicKeyVersionCache = {};

  // =============================================================
  // INITIALISATION
  // =============================================================

  Future<void> initialize({
    required String apiBaseUrl,
    required String authToken,
  }) async {
    try {
      _apiBaseUrl = apiBaseUrl.replaceAll(RegExp(r'/$'), '');

      _authToken = authToken;

      final privateKeyB64 = await _storage.read(
        key: _privateKeyStorage,
      );

      final publicKeyB64 = await _storage.read(
        key: _publicKeyStorage,
      );

      final versionString = await _storage.read(
        key: _keyVersionStorage,
      );

      if (versionString != null) {
        _keyVersion = int.tryParse(versionString) ?? 1;
      }

      // ---------------------------------------------------------
      // Aucune clé locale
      // ---------------------------------------------------------

      if (privateKeyB64 == null || publicKeyB64 == null) {
        debugPrint(
          'ℹ️ No Idjowlê E2E identity key found.',
        );

        await generateAndStoreIdentityKeyPair();
      } else {
        // -------------------------------------------------------
        // Restaurer la clé privée
        // -------------------------------------------------------

        final privateBytes = _decodeBase64(
          privateKeyB64,
        );

        _identityKeyPair =
            await _x25519.newKeyPairFromSeed(
          privateBytes,
        );

        // -------------------------------------------------------
        // Récupérer la clé publique calculée
        // -------------------------------------------------------

        final publicKey =
            await _identityKeyPair!.extractPublicKey();

        final calculatedPublicKeyB64 =
            _encodeBase64(publicKey.bytes);

        // -------------------------------------------------------
        // Vérification anti-corruption
        // -------------------------------------------------------

        if (calculatedPublicKeyB64 != publicKeyB64) {
          throw Exception(
            'Local E2E key pair is corrupted',
          );
        }

        _myPublicKeyB64 = publicKeyB64;
      }

      // Initialiser X3DH
      await _x3dh.initialize();

      _initialized = true;

      debugPrint(
        '✅ Idjowlê E2E V3 initialized (with X3DH + Double Ratchet)',
      );
    } catch (e) {
      debugPrint(
        '❌ E2E initialization error: $e',
      );

      rethrow;
    }
  }

  // =============================================================
  // GÉNÉRER LA CLÉ D'IDENTITÉ
  // =============================================================

  Future<Map<String, String>>
      generateAndStoreIdentityKeyPair() async {
    try {
      final keyPair = await _x25519.newKeyPair();

      final privateKeyBytes =
          await keyPair.extractPrivateKeyBytes();

      final publicKey =
          await keyPair.extractPublicKey();

      final privateKeyB64 =
          _encodeBase64(privateKeyBytes);

      final publicKeyB64 =
          _encodeBase64(publicKey.bytes);

      await _storage.write(
        key: _privateKeyStorage,
        value: privateKeyB64,
      );

      await _storage.write(
        key: _publicKeyStorage,
        value: publicKeyB64,
      );

      await _storage.write(
        key: _keyVersionStorage,
        value: '1',
      );

      _identityKeyPair = keyPair;

      _myPublicKeyB64 = publicKeyB64;

      _keyVersion = 1;

      debugPrint(
        '✅ Idjowlê identity key generated',
      );

      return {
        'private': privateKeyB64,
        'public': publicKeyB64,
        'version': '1',
      };
    } catch (e) {
      debugPrint(
        '❌ Identity key generation error: $e',
      );

      rethrow;
    }
  }

  // =============================================================
  // GETTERS
  // =============================================================

  String? get myPublicKey => _myPublicKeyB64;

  int get myKeyVersion => _keyVersion;

  bool get isInitialized => _initialized;

  // =============================================================
  // FINGERPRINT DE MA CLÉ PUBLIQUE
  // =============================================================

  Future<String> getMyPublicKeyFingerprint() async {
    if (_myPublicKeyB64 == null) {
      throw Exception(
        'E2E not initialized',
      );
    }

    return calculatePublicKeyFingerprint(
      _myPublicKeyB64!,
    );
  }

  // =============================================================
  // FINGERPRINT D'UNE CLÉ PUBLIQUE
  // =============================================================

  Future<String> calculatePublicKeyFingerprint(
    String publicKeyB64,
  ) async {
    final publicKeyBytes =
        _decodeBase64(publicKeyB64);

    final hash =
        await _sha256.hash(publicKeyBytes);

    return _formatFingerprint(
      hash.bytes,
    );
  }

  // =============================================================
  // FORMAT FINGERPRINT
  // =============================================================

  String _formatFingerprint(
    List<int> bytes,
  ) {
    final hex = bytes
        .map(
          (byte) => byte
              .toRadixString(16)
              .padLeft(2, '0')
              .toUpperCase(),
        )
        .join();

    // Exemple:
    //
    // A872193C91F...
    //
    // devient:
    //
    // A872 193C 91F...
    final groups = <String>[];

    for (int i = 0; i < hex.length; i += 4) {
      final end =
          (i + 4 < hex.length) ? i + 4 : hex.length;

      groups.add(
        hex.substring(i, end),
      );
    }

    return groups.join(' ');
  }

  // =============================================================
  // ENREGISTRER MA CLÉ PUBLIQUE SUR FASTAPI
  // =============================================================

  Future<Map<String, dynamic>>
      registerMyPublicKey() async {
    _checkApiConfiguration();

    if (_myPublicKeyB64 == null) {
      throw Exception(
        'Public key unavailable',
      );
    }

    final uri = Uri.parse(
      '$_apiBaseUrl/e2e/keys',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'public_key': _myPublicKeyB64,
        'key_version': _keyVersion,
      }),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to register E2E public key '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    debugPrint(
      '✅ E2E public key registered on FastAPI',
    );

    return data;
  }

  // =============================================================
  // RÉCUPÉRER LA CLÉ PUBLIQUE D'UN UTILISATEUR
  // =============================================================

  Future<String> fetchPublicKey(
    String userId,
  ) async {
    _checkApiConfiguration();

    final cached =
        _publicKeyCache[userId];

    if (cached != null) {
      return cached;
    }

    final uri = Uri.parse(
      '$_apiBaseUrl/e2e/keys/$userId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to fetch public key '
        '($userId): '
        '${response.statusCode} ${response.body}',
      );
    }

    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    final publicKey =
        data['public_key'] as String;

    final keyVersion =
        (data['key_version'] as num?)?.toInt() ?? 1;

    final algorithm =
        data['algorithm'] as String?;

    if (algorithm != 'X25519') {
      throw Exception(
        'Unsupported public key algorithm: $algorithm',
      );
    }

    _publicKeyCache[userId] =
        publicKey;

    _publicKeyVersionCache[userId] =
        keyVersion;

    return publicKey;
  }

  // =============================================================
  // FINGERPRINT D'UN UTILISATEUR
  // =============================================================

  Future<String> getUserKeyFingerprint(
    String userId,
  ) async {
    final publicKey =
        await fetchPublicKey(userId);

    return calculatePublicKeyFingerprint(
      publicKey,
    );
  }

  // =============================================================
  // GETTER CLÉ PUBLIQUE
  // =============================================================

  Future<String> getMyPublicKeyFromStorage() async {
    final publicKeyB64 = await _storage.read(
      key: _publicKeyStorage,
    );

    if (publicKeyB64 == null) {
      throw Exception('No public key found in storage');
    }

    return publicKeyB64;
  }

  // =============================================================
  // INVALIDER LE CACHE
  // =============================================================

  void invalidatePublicKey(
    String userId,
  ) {
    _publicKeyCache.remove(userId);

    _publicKeyVersionCache.remove(userId);
  }

  // =============================================================
  // RÉCUPÉRER LE PREKEY BUNDLE X3DH
  // =============================================================

  Future<Map<String, dynamic>> fetchRecipientPrekeyBundle(
    String userId,
  ) async {
    _checkApiConfiguration();

    final uri = Uri.parse(
      '$_apiBaseUrl/e2e/prekeys/$userId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to fetch prekey bundle '
        '($userId): '
        '${response.statusCode} ${response.body}',
      );
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    return data;
  }

  // =============================================================
  // PUBLIHER MES PREKEYS X3DH
  // =============================================================

  Future<Map<String, dynamic>> publishMyPrekeys() async {
    _checkApiConfiguration();

    final prekeyBundle = await _x3dh.getPrekeyBundle();

    final uri = Uri.parse(
      '$_apiBaseUrl/e2e/prekeys',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(prekeyBundle),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to publish prekeys '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    debugPrint(
      '✅ X3DH prekeys published',
    );

    return data;
  }

  // =============================================================
  // CHIFFRER UN MESSAGE (AVEC X3DH + DOUBLE RATCHET)
  // =============================================================

  Future<Map<String, dynamic>> encryptMessage(
    String plaintext, {
    required String recipientUserId,
    required String conversationId,
    String? senderUserId,
  }) async {
    try {
      if (!_initialized) {
        throw Exception(
          'E2E service is not initialized',
        );
      }

      // ---------------------------------------------------------
      // Récupérer ou créer la session Double Ratchet
      // ---------------------------------------------------------

      DoubleRatchetSession session =
          await _ratchetManager.getOrCreateSession(
        conversationId,
        remoteUserId: recipientUserId,
      );

      // Si pas de session, utiliser X3DH pour en établir une
      if (!session.isInitialized) {
        final recipientPrekeyBundle =
            await fetchRecipientPrekeyBundle(
          recipientUserId,
        );
        
        // Valider le bundle
        _validatePrekeyBundle(recipientPrekeyBundle);

        // Initialiser X3DH
        final x3dhResult =
            await _x3dh.initiateX3DH(
          recipientPrekeyBundle,
        );

        // Créer la session Double Ratchet avec les bonnes clés
        session = DoubleRatchetSession(
          conversationId: conversationId,
          remoteUserId: recipientUserId,
          initialRootKey: x3dhResult.rootKey,
          initialSendingKeyPair: x3dhResult.ephemeralKeyPair,
          remoteIdentityKey: x3dhResult.remoteIdentityKey,
        );

        // Sauvegarder la session
        await _ratchetManager.addSession(conversationId, session);
      }

      // ---------------------------------------------------------
      // Chiffrer avec Double Ratchet
      // ---------------------------------------------------------

      final ratchetMessage =
          await session.encryptMessage(plaintext);

      // Sauvegarder l'état
      await _ratchetManager.saveSession(conversationId);

      // ---------------------------------------------------------
      // MESSAGE FINAL
      // ---------------------------------------------------------

      final result = {
        'conversation_id': conversationId,
        'recipient_id': recipientUserId,
        'sender_id': senderUserId ?? _myUserId,
        'version': 3,
        'algorithm':
            'X3DH-DoubleRatchet-AES-256-GCM',
        'ratchet_message': ratchetMessage.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint(
        '✅ Message encrypted with X3DH + Double Ratchet',
      );

      return result;
    } catch (e) {
      debugPrint(
        '❌ Message encryption error: $e',
      );
      rethrow;
    }
  }

  // =============================================================
  // VALIDATION DES PREKEYS
  // =============================================================

  void _validatePrekeyBundle(Map<String, dynamic> bundle) {
    final requiredKeys = [
      'identity_key',
      'signed_prekey',
      'signed_prekey_signature',
    ];

    for (final key in requiredKeys) {
      if (!bundle.containsKey(key)) {
        throw Exception('Missing required prekey: $key');
      }
    }

    // TODO: Vérifier la signature du SPK
    debugPrint('✅ Prekey bundle validated');
  }

  // =============================================================
  // ENVOYER UN MESSAGE CHIFFRÉ À FASTAPI
  // =============================================================

  Future<Map<String, dynamic>>
      encryptAndSendMessage(
    String plaintext, {
    required String recipientUserId,
    required String conversationId,
    String? senderUserId,
  }) async {
    _checkApiConfiguration();

    // -----------------------------------------------------------
    // Chiffrement LOCAL
    // -----------------------------------------------------------

    final encrypted =
        await encryptMessage(
      plaintext,
      recipientUserId: recipientUserId,
      conversationId: conversationId,
      senderUserId: senderUserId,
    );

    // -----------------------------------------------------------
    // Construction du body selon la version
    // -----------------------------------------------------------

    final body = {
      'conversation_id': encrypted['conversation_id'],
      'recipient_id': encrypted['recipient_id'],
      'sender_id': encrypted['sender_id'],
      'version': encrypted['version'],
      'algorithm': encrypted['algorithm'],
      'timestamp': encrypted['timestamp'],
      'ratchet_message': encrypted['ratchet_message'],
    };

    // -----------------------------------------------------------
    // FastAPI
    // -----------------------------------------------------------

    final uri = Uri.parse(
      '$_apiBaseUrl/e2e/messages',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to send encrypted message '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    debugPrint(
      '✅ Encrypted message sent to FastAPI',
    );

    return data;
  }

  // =============================================================
  // DÉCHIFFRER UN MESSAGE (AVEC X3DH + DOUBLE RATCHET)
  // =============================================================

  Future<String> decryptMessage(
    Map<String, dynamic> message, {
    required String senderUserId,
    required String recipientUserId,
  }) async {
    try {
      if (!_initialized) {
        throw Exception(
          'E2E service is not initialized',
        );
      }

      final version = (message['version'] as num?)?.toInt();
      final conversationId = message['conversation_id'] as String?;

      if (conversationId == null) {
        throw Exception('Missing conversation_id');
      }

      // Rétrocompatibilité V2
      if (version == 2) {
        return await _decryptMessageV2(
          message,
          senderUserId: senderUserId,
          recipientUserId: recipientUserId,
        );
      }

      if (version != 3) {
        throw Exception('Unsupported E2E version: $version');
      }

      // Récupérer la session
      DoubleRatchetSession session = await _ratchetManager.getOrCreateSession(
        conversationId,
        remoteUserId: senderUserId,
      );

      // Si pas de session, répondre au X3DH
      if (!session.isInitialized) {
        final ratchetMessageData = message['ratchet_message'] as Map<String, dynamic>;
        final ratchetMessage = RatchetMessage.fromJson(ratchetMessageData);

        // Récupérer les prekeys de l'expéditeur
        final senderPrekeyBundle = await fetchRecipientPrekeyBundle(
          senderUserId,
        );

        // Répondre au X3DH
        final x3dhResponse = await _x3dh.respondX3DH(
          identityPublicKey: senderPrekeyBundle['identity_key'] as String,
          signedPrekeyPublicKey: senderPrekeyBundle['signed_prekey'] as String,
          signedPrekeySignature: senderPrekeyBundle['signed_prekey_signature'] as String,
          ephemeralPublicKey: ratchetMessage.ratchetPublicKey,
        );

        // Créer la session
        session = DoubleRatchetSession(
          conversationId: conversationId,
          remoteUserId: senderUserId,
          initialRootKey: x3dhResponse.rootKey,
          initialSendingKeyPair: x3dhResponse.ephemeralKeyPair,
          remoteIdentityKey: x3dhResponse.remoteIdentityKey,
        );

        // Sauvegarder la session
        await _ratchetManager.addSession(conversationId, session);
      }

      // Déchiffrer avec Double Ratchet
      final ratchetMessageData = message['ratchet_message'] as Map<String, dynamic>;
      final ratchetMessage = RatchetMessage.fromJson(ratchetMessageData);

      final plaintext = await session.decryptMessage(ratchetMessage);

      // Sauvegarder l'état
      await _ratchetManager.saveSession(conversationId);

      return plaintext;
    } catch (e) {
      debugPrint('❌ Message decryption error: $e');
      rethrow;
    }
  }

  // =============================================================
  // DÉCHIFFREMENT VERSION 2 (RÉTROCOMPATIBILITÉ)
  // =============================================================

  Future<String> _decryptMessageV2(
    Map<String, dynamic> message, {
    required String senderUserId,
    required String recipientUserId,
  }) async {
    final algorithm =
        message['algorithm'];

    if (algorithm !=
        'X25519-HKDF-SHA256-AES-256-GCM') {
      throw Exception(
        'Unsupported E2E algorithm: $algorithm',
      );
    }

    final ephemeralPublicKeyB64 =
        message['ephemeral_public_key'] as String?;
    if (ephemeralPublicKeyB64 == null) {
      throw Exception(
        'Missing ephemeral public key',
      );
    }

    final ephemeralPublicKeyBytes =
        _decodeBase64(ephemeralPublicKeyB64);
    final ephemeralPublicKey = SimplePublicKey(
      ephemeralPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: _identityKeyPair!,
      remotePublicKey: ephemeralPublicKey,
    );

    final aesSecret = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      info: utf8.encode('Idjowle-E2E-V2-AES256-GCM'),
    );

    final aesKeyBytes = await aesSecret.extractBytes();
    final aesKey = enc.Key(Uint8List.fromList(aesKeyBytes));

    final nonce = _decodeBase64(message['nonce'] as String);
    final iv = enc.IV(nonce);

    final ciphertext = _decodeBase64(message['ciphertext'] as String);

    final conversationId = message['conversation_id'] as String;
    final associatedData = utf8.encode(
      '$conversationId|$senderUserId|$recipientUserId|2',
    );

    final encrypter = enc.Encrypter(
      enc.AES(aesKey, mode: enc.AESMode.gcm),
    );

    final plaintext = encrypter.decryptBytes(
      enc.Encrypted(Uint8List.fromList(ciphertext)),
      iv: iv,
      associatedData: Uint8List.fromList(associatedData),
    );

    return utf8.decode(plaintext);
  }

  // =============================================================
  // RÉCUPÉRER LES MESSAGES CHIFFRÉS
  // =============================================================

  Future<List<Map<String, dynamic>>>
      fetchEncryptedMessages(
    String conversationId,
  ) async {
    _checkApiConfiguration();

    final uri = Uri.parse(
      '$_apiBaseUrl/e2e/messages/$conversationId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch encrypted messages '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    final messages =
        data['messages'] as List<dynamic>? ?? [];

    return messages
        .map(
          (message) =>
              Map<String, dynamic>.from(
            message as Map,
          ),
        )
        .toList();
  }

  // =============================================================
  // RÉCUPÉRER + DÉCHIFFRER
  // =============================================================

  Future<List<Map<String, dynamic>>>
      fetchAndDecryptMessages(
    String conversationId, {
    required String myUserId,
  }) async {
    final encryptedMessages =
        await fetchEncryptedMessages(
      conversationId,
    );

    final decryptedMessages =
        <Map<String, dynamic>>[];

    for (final message
        in encryptedMessages) {
      try {
        final senderId =
            message['sender_id'] as String;

        final recipientId =
            message['recipient_id'] as String;

        final plaintext =
            await decryptMessage(
          message,
          senderUserId: senderId,
          recipientUserId: recipientId,
        );

        decryptedMessages.add({
          ...message,
          'plaintext': plaintext,
        });
      } catch (e) {
        // -------------------------------------------------------
        // IMPORTANT:
        // Un message impossible à déchiffrer ne doit pas
        // empêcher tous les autres messages de s'afficher.
        // -------------------------------------------------------

        debugPrint(
          '⚠️ Unable to decrypt message '
          '${message['id']}: $e',
        );

        decryptedMessages.add({
          ...message,
          'plaintext': null,
          'decryption_error': true,
        });
      }
    }

    return decryptedMessages;
  }

  // =============================================================
  // VÉRIFIER UNE CLÉ PUBLIQUE
  // =============================================================

  Future<bool> verifyUserFingerprint(
    String userId,
    String expectedFingerprint,
  ) async {
    final fingerprint =
        await getUserKeyFingerprint(
      userId,
    );

    return fingerprint ==
        expectedFingerprint;
  }

  // =============================================================
  // SUPPRIMER LES CLÉS LOCALES
  // =============================================================

  Future<void> deleteLocalIdentityKeys() async {
    await _storage.delete(
      key: _privateKeyStorage,
    );

    await _storage.delete(
      key: _publicKeyStorage,
    );

    await _storage.delete(
      key: _keyVersionStorage,
    );

    _identityKeyPair = null;

    _myPublicKeyB64 = null;

    _keyVersion = 1;

    _initialized = false;

    debugPrint(
      '⚠️ Idjowlê E2E identity keys deleted',
    );
  }

  // =============================================================
  // CLEAR CACHE
  // =============================================================

  void clearPublicKeyCache() {
    _publicKeyCache.clear();

    _publicKeyVersionCache.clear();
  }

  // =============================================================
  // BASE64URL
  // =============================================================

  String _encodeBase64(
    List<int> bytes,
  ) {
    return base64Url
        .encode(bytes)
        .replaceAll('=', '');
  }

  Uint8List _decodeBase64(
    String value,
  ) {
    var normalized = value;

    final mod =
        normalized.length % 4;

    if (mod != 0) {
      normalized += '=' * (4 - mod);
    }

    return Uint8List.fromList(
      base64Url.decode(normalized),
    );
  }

  // =============================================================
  // VÉRIFIER CONFIG API
  // =============================================================

  void _checkApiConfiguration() {
    if (_apiBaseUrl == null ||
        _authToken == null) {
      throw Exception(
        'E2E API is not configured. '
        'Call initialize() first.',
      );
    }
  }
}
