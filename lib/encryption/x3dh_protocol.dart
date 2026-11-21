library;

// ===============================================================
// X3DH PROTOCOL (Extended Triple Diffie-Hellman) - VERSION CORRIGÉE
/// ===============================================================
///
/// X3DH est utilisé pour établir une session initiale entre deux parties
/// avec une forte forward secrecy.
///
/// Les clés impliquées:
/// - Identity Key (IK): Clé à long terme de chaque utilisateur
/// - Signed Prekey (SPK): Clé signée par IK, changée périodiquement
/// - One-time Prekey (OPK): Clé à usage unique pour chaque session
/// - Ephemeral Key (EK): Clé éphémère générée pour chaque session
///
/// Les 3 échanges DH:
/// - DH1: EK_sender + IK_recipient
/// - DH2: IK_sender + SPK_recipient
/// - DH3: EK_sender + SPK_recipient (optionnel avec OPK)
/// ===============================================================

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class X3DHProtocol {
  static final X3DHProtocol _instance = X3DHProtocol._internal();

  factory X3DHProtocol() => _instance;

  X3DHProtocol._internal();

  final X25519 _x25519 = X25519();
  final Hkdf _hkdf = Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 64, // 32 bytes pour RK + 32 bytes pour CK
  );

  // =============================================================
  // STORAGE
  // =============================================================

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _identityPrivateKeyKey = 'x3dh_identity_private_key';
  static const String _identityPublicKeyKey = 'x3dh_identity_public_key';
  static const String _signedPrekeyPrivateKeyKey = 'x3dh_signed_prekey_private_key';
  static const String _signedPrekeyPublicKeyKey = 'x3dh_signed_prekey_public_key';
  static const String _signedPrekeySignatureKey = 'x3dh_signed_prekey_signature';
  static const String _oneTimePrekeysKey = 'x3dh_one_time_prekeys';
  static const String _prekeyVersionKey = 'x3dh_prekey_version';

  // =============================================================
  // KEYS
  // =============================================================

  SimpleKeyPair? _identityKeyPair;
  SimpleKeyPair? _signedPrekeyPair;
  String? _signedPrekeySignature;
  final List<SimpleKeyPair> _oneTimePrekeys = [];
  int _prekeyVersion = 1;

  // =============================================================
  // INITIALISATION
  // =============================================================

  Future<void> initialize() async {
    try {
      // Charger les clés existantes
      final identityPrivateKeyB64 = await _storage.read(key: _identityPrivateKeyKey);
      final identityPublicKeyB64 = await _storage.read(key: _identityPublicKeyKey);
      final signedPrekeyPrivateKeyB64 = await _storage.read(key: _signedPrekeyPrivateKeyKey);
      final signedPrekeyPublicKeyB64 = await _storage.read(key: _signedPrekeyPublicKeyKey);
      final signedPrekeySignature = await _storage.read(key: _signedPrekeySignatureKey);
      final oneTimePrekeysJson = await _storage.read(key: _oneTimePrekeysKey);
      final versionString = await _storage.read(key: _prekeyVersionKey);

      if (versionString != null) {
        _prekeyVersion = int.tryParse(versionString) ?? 1;
      }

      // Restaurer la clé d'identité
      if (identityPrivateKeyB64 != null && identityPublicKeyB64 != null) {
        final privateBytes = _decodeBase64(identityPrivateKeyB64);
        _identityKeyPair = await _x25519.newKeyPairFromSeed(privateBytes);
      }

      // Restaurer la signed prekey
      if (signedPrekeyPrivateKeyB64 != null &&
          signedPrekeyPublicKeyB64 != null &&
          signedPrekeySignature != null) {
        final privateBytes = _decodeBase64(signedPrekeyPrivateKeyB64);
        _signedPrekeyPair = await _x25519.newKeyPairFromSeed(privateBytes);
        _signedPrekeySignature = signedPrekeySignature;
      }

      // Restaurer les one-time prekeys
      if (oneTimePrekeysJson != null) {
        final List<dynamic> prekeysList = jsonDecode(oneTimePrekeysJson) as List;
        for (final prekeyData in prekeysList) {
          final privateBytes = _decodeBase64(prekeyData['private'] as String);
          final keyPair = await _x25519.newKeyPairFromSeed(privateBytes);
          _oneTimePrekeys.add(keyPair);
        }
      }

      // Générer les clés si elles n'existent pas
      if (_identityKeyPair == null) {
        await _generateIdentityKey();
      }

      if (_signedPrekeyPair == null) {
        await _generateSignedPrekey();
      }

      // S'assurer d'avoir assez de one-time prekeys
      if (_oneTimePrekeys.length < 10) {
        await _generateOneTimePrekeys(count: 20);
      }

      debugPrint('✅ X3DH initialized');
    } catch (e) {
      debugPrint('❌ X3DH initialization error: $e');
      rethrow;
    }
  }

  // =============================================================
  // GÉNÉRATION DES CLÉS
  // =============================================================

  Future<void> _generateIdentityKey() async {
    _identityKeyPair = await _x25519.newKeyPair();

    final privateKeyBytes = await _identityKeyPair!.extractPrivateKeyBytes();
    final publicKey = await _identityKeyPair!.extractPublicKey();

    await _storage.write(
      key: _identityPrivateKeyKey,
      value: _encodeBase64(privateKeyBytes),
    );
    await _storage.write(
      key: _identityPublicKeyKey,
      value: _encodeBase64(publicKey.bytes),
    );

    debugPrint('✅ Identity key generated');
  }

  Future<void> _generateSignedPrekey() async {
    _signedPrekeyPair = await _x25519.newKeyPair();

    final privateKeyBytes = await _signedPrekeyPair!.extractPrivateKeyBytes();
    final publicKey = await _signedPrekeyPair!.extractPublicKey();

    // Signer la signed prekey avec la clé d'identité
    final signature = await _signKey(publicKey.bytes, _identityKeyPair!);

    _signedPrekeySignature = _encodeBase64(signature);

    await _storage.write(
      key: _signedPrekeyPrivateKeyKey,
      value: _encodeBase64(privateKeyBytes),
    );
    await _storage.write(
      key: _signedPrekeyPublicKeyKey,
      value: _encodeBase64(publicKey.bytes),
    );
    await _storage.write(
      key: _signedPrekeySignatureKey,
      value: _signedPrekeySignature!,
    );

    _prekeyVersion++;
    await _storage.write(
      key: _prekeyVersionKey,
      value: _prekeyVersion.toString(),
    );

    debugPrint('✅ Signed prekey generated');
  }

  Future<void> _generateOneTimePrekeys({required int count}) async {
    for (int i = 0; i < count; i++) {
      final keyPair = await _x25519.newKeyPair();
      _oneTimePrekeys.add(keyPair);
    }

    await _saveOneTimePrekeys();
    debugPrint('✅ Generated $count one-time prekeys');
  }

  Future<void> _saveOneTimePrekeys() async {
    final prekeysList = <Map<String, dynamic>>[];
    for (final keyPair in _oneTimePrekeys) {
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      prekeysList.add({
        'private': _encodeBase64(privateKeyBytes),
      });
    }

    await _storage.write(
      key: _oneTimePrekeysKey,
      value: jsonEncode(prekeysList),
    );
  }

  // =============================================================
  // SIGNATURE
  // =============================================================

  Future<Uint8List> _signKey(
    List<int> keyBytes,
    SimpleKeyPair signingKey,
  ) async {
    // Pour simplifier, on utilise HKDF comme "signature"
    // En production, utiliser Ed25519 pour de vraies signatures
    final privateKeyBytes = await signingKey.extractPrivateKeyBytes();
    final combined = Uint8List(keyBytes.length + privateKeyBytes.length);
    combined.setAll(0, keyBytes);
    combined.setAll(keyBytes.length, privateKeyBytes);

    final hash = await Sha256().hash(combined);
    return Uint8List.fromList(hash.bytes);
  }

  // =============================================================
  // PUBLICATION DES PREKEYS
  // =============================================================

  Future<Map<String, dynamic>> getPrekeyBundle() async {
    if (_identityKeyPair == null || _signedPrekeyPair == null) {
      throw Exception('X3DH not initialized');
    }

    final identityPublicKey = await _identityKeyPair!.extractPublicKey();
    final signedPrekeyPublicKey = await _signedPrekeyPair!.extractPublicKey();

    // Prendre une one-time prekey si disponible
    String? oneTimePrekeyPublicKeyB64;
    if (_oneTimePrekeys.isNotEmpty) {
      final opk = _oneTimePrekeys.removeAt(0);
      final opkPublicKey = await opk.extractPublicKey();
      oneTimePrekeyPublicKeyB64 = _encodeBase64(opkPublicKey.bytes);
      await _saveOneTimePrekeys();
    }

    return {
      'identity_key': _encodeBase64(identityPublicKey.bytes),
      'signed_prekey': _encodeBase64(signedPrekeyPublicKey.bytes),
      'signed_prekey_signature': _signedPrekeySignature,
      'one_time_prekey': oneTimePrekeyPublicKeyB64,
      'prekey_version': _prekeyVersion,
    };
  }

  // =============================================================
  // X3DH INITIATION
  // =============================================================

  Future<X3DHInitResult> initiateX3DH(
    Map<String, dynamic> recipientPrekeyBundle,
  ) async {
    if (_identityKeyPair == null) {
      throw Exception('X3DH not initialized');
    }

    // Extraire les clés du destinataire
    final recipientIdentityKeyBytes = _decodeBase64(
      recipientPrekeyBundle['identity_key'] as String,
    );
    final recipientSignedPrekeyBytes = _decodeBase64(
      recipientPrekeyBundle['signed_prekey'] as String,
    );
    final recipientOneTimePrekeyBytes =
        recipientPrekeyBundle['one_time_prekey'] != null
            ? _decodeBase64(recipientPrekeyBundle['one_time_prekey'] as String)
            : null;

    final recipientIdentityKey = SimplePublicKey(
      recipientIdentityKeyBytes,
      type: KeyPairType.x25519,
    );
    final recipientSignedPrekey = SimplePublicKey(
      recipientSignedPrekeyBytes,
      type: KeyPairType.x25519,
    );

    // Générer clé éphémère pour cette session
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // DH1: Ephemeral (sender) + Identity (recipient)
    final dh1 = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientIdentityKey,
    );

    // DH2: Identity (sender) + Signed Prekey (recipient)
    final dh2 = await _x25519.sharedSecretKey(
      keyPair: _identityKeyPair!,
      remotePublicKey: recipientSignedPrekey,
    );

    // DH3: Ephemeral (sender) + Signed Prekey (recipient)
    final dh3 = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientSignedPrekey,
    );

    // DH4 (optionnel): Ephemeral (sender) + One-Time Prekey (recipient)
    SecretKey? dh4;
    if (recipientOneTimePrekeyBytes != null) {
      final recipientOneTimePrekey = SimplePublicKey(
        recipientOneTimePrekeyBytes,
        type: KeyPairType.x25519,
      );
      dh4 = await _x25519.sharedSecretKey(
        keyPair: ephemeralKeyPair,
        remotePublicKey: recipientOneTimePrekey,
      );
    }

    // Combiner tous les secrets
    final combinedSecret = await _combineSecrets(
      [dh1, dh2, dh3, if (dh4 != null) dh4],
    );

    // Dériver la clé de session (split en RK + CK)
    final sessionKey = await _hkdf.deriveKey(
      secretKey: combinedSecret,
      info: utf8.encode('X3DH-Session-Key'),
    );
    
    final sessionKeyBytes = await sessionKey.extractBytes();
    final rootKey = SecretKey(sessionKeyBytes.sublist(0, 32));
    final chainKey = SecretKey(sessionKeyBytes.sublist(32, 64));

    return X3DHInitResult(
      rootKey: rootKey,
      chainKey: chainKey,
      ephemeralPublicKey: _encodeBase64(ephemeralPublicKey.bytes),
      ephemeralKeyPair: ephemeralKeyPair,
      remoteIdentityKey: recipientIdentityKey,
    );
  }

  // =============================================================
  // X3DH RESPONSE (pour le destinataire)
  // =============================================================

  Future<X3DHResponseResult> respondX3DH({
    required String identityPublicKey,
    required String signedPrekeyPublicKey,
    required String signedPrekeySignature,
    required String ephemeralPublicKey,
  }) async {
    if (_identityKeyPair == null || _signedPrekeyPair == null) {
      throw Exception('X3DH not initialized');
    }

    final senderEphemeralPublicKeyBytes = _decodeBase64(ephemeralPublicKey);
    final senderEphemeralPublicKey = SimplePublicKey(
      senderEphemeralPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    // DH1: Ephemeral (sender) + Identity (recipient)
    final dh1 = await _x25519.sharedSecretKey(
      keyPair: _identityKeyPair!,
      remotePublicKey: senderEphemeralPublicKey,
    );

    // DH2: Identity (sender) + Signed Prekey (recipient)
    final dh2 = await _x25519.sharedSecretKey(
      keyPair: _signedPrekeyPair!,
      remotePublicKey: senderEphemeralPublicKey,
    );

    // DH3: Ephemeral (sender) + Signed Prekey (recipient)
    final dh3 = await _x25519.sharedSecretKey(
      keyPair: _signedPrekeyPair!,
      remotePublicKey: senderEphemeralPublicKey,
    );

    // Combiner les secrets
    final combinedSecret = await _combineSecrets([dh1, dh2, dh3]);

    // Dériver la clé de session (split en RK + CK)
    final sessionKey = await _hkdf.deriveKey(
      secretKey: combinedSecret,
      info: utf8.encode('X3DH-Session-Key'),
    );
    
    final sessionKeyBytes = await sessionKey.extractBytes();
    final rootKey = SecretKey(sessionKeyBytes.sublist(0, 32));
    final chainKey = SecretKey(sessionKeyBytes.sublist(32, 64));

    // Générer une clé éphémère pour répondre
    final ephemeralKeyPair = await _x25519.newKeyPair();

    return X3DHResponseResult(
      rootKey: rootKey,
      chainKey: chainKey,
      ephemeralKeyPair: ephemeralKeyPair,
      remoteIdentityKey: senderEphemeralPublicKey,
    );
  }

  // =============================================================
  // UTILITAIRES
  // =============================================================

  Future<SecretKey> _combineSecrets(List<SecretKey> secrets) async {
    // Concaténer tous les secrets
    final combined = <int>[];
    for (final secret in secrets) {
      final bytes = await secret.extractBytes();
      combined.addAll(bytes);
    }

    // Hasher pour obtenir une clé unique
    final hash = await Sha256().hash(combined);
    return SecretKey(hash.bytes);
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
  // ROTATION DES PREKEYS
  // =============================================================

  Future<void> rotateSignedPrekey() async {
    await _generateSignedPrekey();
    debugPrint('✅ Signed prekey rotated');
  }

  Future<void> regenerateOneTimePrekeys() async {
    _oneTimePrekeys.clear();
    await _generateOneTimePrekeys(count: 20);
    debugPrint('✅ One-time prekeys regenerated');
  }

  // =============================================================
  // GETTERS
  // =============================================================

  Future<String> get myIdentityPublicKey async {
    if (_identityKeyPair == null) {
      throw Exception('X3DH not initialized');
    }
    final publicKey = await _identityKeyPair!.extractPublicKey();
    return _encodeBase64(publicKey.bytes);
  }

  int get prekeyVersion => _prekeyVersion;
}

/// ===============================================================
/// X3DH INIT RESULT
/// ===============================================================

class X3DHInitResult {
  final SecretKey rootKey;
  final SecretKey chainKey;
  final String ephemeralPublicKey;
  final SimpleKeyPair ephemeralKeyPair;
  final SimplePublicKey remoteIdentityKey;

  X3DHInitResult({
    required this.rootKey,
    required this.chainKey,
    required this.ephemeralPublicKey,
    required this.ephemeralKeyPair,
    required this.remoteIdentityKey,
  });
}

/// ===============================================================
/// X3DH RESPONSE RESULT
/// ===============================================================

class X3DHResponseResult {
  final SecretKey rootKey;
  final SecretKey chainKey;
  final SimpleKeyPair ephemeralKeyPair;
  final SimplePublicKey remoteIdentityKey;

  X3DHResponseResult({
    required this.rootKey,
    required this.chainKey,
    required this.ephemeralKeyPair,
    required this.remoteIdentityKey,
  });
}
