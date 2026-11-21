// ===============================================================
// RATCHET MESSAGE MODEL
// ===============================================================

class RatchetMessage {
  final int version;
  final int messageNumber;
  final String ratchetPublicKey;
  final String ciphertext;
  final String nonce;
  final int previousChainLength;

  RatchetMessage({
    required this.version,
    required this.messageNumber,
    required this.ratchetPublicKey,
    required this.ciphertext,
    required this.nonce,
    this.previousChainLength = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'message_number': messageNumber,
      'ratchet_public_key': ratchetPublicKey,
      'ciphertext': ciphertext,
      'nonce': nonce,
      'previous_chain_length': previousChainLength,
    };
  }

  static RatchetMessage fromJson(Map<String, dynamic> json) {
    return RatchetMessage(
      version: json['version'] as int,
      messageNumber: json['message_number'] as int,
      ratchetPublicKey: json['ratchet_public_key'] as String,
      ciphertext: json['ciphertext'] as String,
      nonce: json['nonce'] as String,
      previousChainLength: json['previous_chain_length'] as int? ?? 0,
    );
  }
}
