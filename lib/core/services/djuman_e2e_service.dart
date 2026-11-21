import 'message_encryption_service.dart';

/// Service E2E pour DJUMAN
/// Gère le chiffrement/déchiffrement des messages sensibles dans DJUMAN
class DjumanE2EService {
  static final DjumanE2EService _instance = DjumanE2EService._internal();
  
  factory DjumanE2EService() => _instance;
  
  DjumanE2EService._internal();
  
  final MessageEncryptionService _encryptionService = MessageEncryptionService();
  
  bool _initialized = false;
  
  /// Initialiser le service E2E pour DJUMAN
  Future<void> initialize({
    required String apiBaseUrl,
    required String authToken,
    required String userId,
  }) async {
    if (_initialized) return;
    
    await _encryptionService.initialize(
      apiBaseUrl: apiBaseUrl,
      authToken: authToken,
    );
    
    // X3DH est déjà initialisé dans initialize()
    // Publier les prekeys
    await _encryptionService.publishMyPrekeys();
    
    _initialized = true;
  }
  
  /// Chiffrer un message pour une conversation DJUMAN
  Future<Map<String, dynamic>> encryptMessage({
    required String plaintext,
    required String recipientUserId,
    required String conversationId,
    String? senderUserId,
  }) async {
    if (!_initialized) {
      throw Exception('DjumanE2EService not initialized');
    }
    
    return await _encryptionService.encryptMessage(
      plaintext,
      recipientUserId: recipientUserId,
      conversationId: conversationId,
      senderUserId: senderUserId,
    );
  }
  
  /// Envoyer un message chiffré
  Future<Map<String, dynamic>> sendEncryptedMessage({
    required String plaintext,
    required String recipientUserId,
    required String conversationId,
    String? senderUserId,
  }) async {
    if (!_initialized) {
      throw Exception('DjumanE2EService not initialized');
    }
    
    return await _encryptionService.encryptAndSendMessage(
      plaintext,
      recipientUserId: recipientUserId,
      conversationId: conversationId,
      senderUserId: senderUserId,
    );
  }
  
  /// Déchiffrer un message reçu
  Future<String> decryptMessage({
    required Map<String, dynamic> encryptedMessage,
    required String senderUserId,
    required String recipientUserId,
  }) async {
    if (!_initialized) {
      throw Exception('DjumanE2EService not initialized');
    }
    
    return await _encryptionService.decryptMessage(
      encryptedMessage,
      senderUserId: senderUserId,
      recipientUserId: recipientUserId,
    );
  }
  
  /// Générer un ID de conversation pour DJUMAN
  String generateConversationId({
    required String entityType, // 'project', 'task', 'collaboration'
    required String entityId,
  }) {
    return 'djuman_${entityType}_$entityId';
  }
  
  /// Obtenir la clé publique de l'utilisateur
  Future<String> getMyPublicKey() async {
    if (!_initialized) {
      throw Exception('DjumanE2EService not initialized');
    }
    
    return await _encryptionService.getMyPublicKeyFromStorage();
  }
  
  /// Obtenir l'empreinte de la clé publique
  Future<String> getMyPublicKeyFingerprint() async {
    if (!_initialized) {
      throw Exception('DjumanE2EService not initialized');
    }
    
    final publicKey = await getMyPublicKey();
    return await _encryptionService.calculatePublicKeyFingerprint(publicKey);
  }
  
  bool get isInitialized => _initialized;
}
