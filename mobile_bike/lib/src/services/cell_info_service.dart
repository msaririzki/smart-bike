import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/cell_info_snapshot.dart';

class CellInfoService {
  static const _channel = MethodChannel('com.smartbike.mobile_bike/cell_info');

  Future<CellInfoSnapshot?> currentServingCell() async {
    if (!Platform.isAndroid) return null;

    try {
      final raw = await _channel
          .invokeMapMethod<dynamic, dynamic>('getServingCell')
          .timeout(const Duration(seconds: 2));
      if (raw == null || raw['cell_id'] == null) return null;
      return CellInfoSnapshot.fromMap(raw);
    } catch (_) {
      return null;
    }
  }
}
