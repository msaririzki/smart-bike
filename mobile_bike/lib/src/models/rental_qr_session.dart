class RentalQrSession {
  RentalQrSession({
    required this.token,
    required this.payload,
    required this.expiresAt,
    required this.bikeCode,
    required this.bikeName,
    required this.bikeId,
  });

  factory RentalQrSession.fromJson(Map<String, dynamic> json) {
    final bike = json['bike'] as Map<String, dynamic>? ?? {};
    return RentalQrSession(
      token: json['token'] as String,
      payload: json['payload'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      bikeId: bike['id'] as int? ?? 0,
      bikeCode: bike['code'] as String? ?? '',
      bikeName: bike['name'] as String? ?? '',
    );
  }

  final String token;
  final String payload;
  final DateTime expiresAt;
  final int bikeId;
  final String bikeCode;
  final String bikeName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingDuration {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
