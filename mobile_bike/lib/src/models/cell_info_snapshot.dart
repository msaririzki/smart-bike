class CellInfoSnapshot {
  const CellInfoSnapshot({
    required this.radioType,
    this.operatorName,
    this.mcc,
    this.mnc,
    this.cellId,
    this.tacOrLac,
    this.pciOrPsc,
    this.signalDbm,
    this.rsrpDbm,
    this.rsrqDb,
    this.sinrDb,
    this.isRegistered = false,
  });

  final String radioType;
  final String? operatorName;
  final String? mcc;
  final String? mnc;
  final String? cellId;
  final String? tacOrLac;
  final String? pciOrPsc;
  final int? signalDbm;
  final int? rsrpDbm;
  final double? rsrqDb;
  final double? sinrDb;
  final bool isRegistered;

  String? get identityKey {
    if (cellId == null || cellId!.isEmpty) return null;
    return '${mcc ?? ''}|${mnc ?? ''}|$radioType|$cellId|${tacOrLac ?? ''}';
  }

  String get shortLabel {
    final operator = operatorName == null || operatorName!.isEmpty
        ? 'Operator'
        : operatorName!;
    final id = cellId == null || cellId!.isEmpty ? '-' : cellId!;
    return '$operator $radioType/$id';
  }

  factory CellInfoSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return CellInfoSnapshot(
      radioType: map['radio_type']?.toString() ?? 'UNKNOWN',
      operatorName: map['operator_name']?.toString(),
      mcc: map['mcc']?.toString(),
      mnc: map['mnc']?.toString(),
      cellId: map['cell_id']?.toString(),
      tacOrLac: map['tac_or_lac']?.toString(),
      pciOrPsc: map['pci_or_psc']?.toString(),
      signalDbm: _toInt(map['signal_dbm']),
      rsrpDbm: _toInt(map['rsrp_dbm']),
      rsrqDb: _toDouble(map['rsrq_db']),
      sinrDb: _toDouble(map['sinr_db']),
      isRegistered: map['is_registered'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'radio_type': radioType,
      if (operatorName != null) 'operator_name': operatorName,
      if (mcc != null) 'mcc': mcc,
      if (mnc != null) 'mnc': mnc,
      if (cellId != null) 'cell_id': cellId,
      if (tacOrLac != null) 'tac_or_lac': tacOrLac,
      if (pciOrPsc != null) 'pci_or_psc': pciOrPsc,
      if (signalDbm != null) 'signal_dbm': signalDbm,
      if (rsrpDbm != null) 'rsrp_dbm': rsrpDbm,
      if (rsrqDb != null) 'rsrq_db': rsrqDb,
      if (sinrDb != null) 'sinr_db': sinrDb,
      'is_registered': isRegistered,
    };
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
