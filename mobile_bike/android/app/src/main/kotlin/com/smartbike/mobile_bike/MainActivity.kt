package com.smartbike.mobile_bike

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.telephony.CellIdentityGsm
import android.telephony.CellIdentityLte
import android.telephony.CellIdentityNr
import android.telephony.CellIdentityWcdma
import android.telephony.CellInfo
import android.telephony.CellInfoGsm
import android.telephony.CellInfoLte
import android.telephony.CellInfoNr
import android.telephony.CellInfoWcdma
import android.telephony.CellSignalStrengthLte
import android.telephony.TelephonyManager
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val cellInfoChannel = "com.smartbike.mobile_bike/cell_info"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cellInfoChannel).setMethodCallHandler { call, result ->
            if (call.method == "getServingCell") {
                result.success(readServingCell())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun readServingCell(): Map<String, Any?>? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED
        ) {
            return null
        }

        val telephony = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val cells = try {
            telephony.allCellInfo
        } catch (_: SecurityException) {
            null
        } catch (_: Exception) {
            null
        } ?: return null

        val servingCell = cells.firstOrNull { it.isRegistered } ?: cells.firstOrNull() ?: return null

        return cellInfoToMap(servingCell, telephony.networkOperatorName)
    }

    private fun cellInfoToMap(cell: CellInfo, operatorName: String?): Map<String, Any?>? {
        return when (cell) {
            is CellInfoLte -> lteToMap(cell, operatorName)
            is CellInfoWcdma -> wcdmaToMap(cell, operatorName)
            is CellInfoGsm -> gsmToMap(cell, operatorName)
            is CellInfoNr -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) nrToMap(cell, operatorName) else null
            else -> null
        }
    }

    private fun lteToMap(cell: CellInfoLte, operatorName: String?): Map<String, Any?> {
        val identity = cell.cellIdentity
        val signal = cell.cellSignalStrength

        return baseMap("LTE", operatorName, cell.isRegistered).plus(
            mapOf(
                "mcc" to mcc(identity),
                "mnc" to mnc(identity),
                "cell_id" to cleanInt(identity.ci)?.toString(),
                "tac_or_lac" to cleanInt(identity.tac)?.toString(),
                "pci_or_psc" to cleanInt(identity.pci)?.toString(),
                "signal_dbm" to cleanSignal(signal.dbm),
                "rsrp_dbm" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) cleanSignal(signal.rsrp) else null,
                "rsrq_db" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) cleanSignal(signal.rsrq)?.toDouble() else null,
                "sinr_db" to lteSinr(signal),
            )
        )
    }

    private fun nrToMap(cell: CellInfoNr, operatorName: String?): Map<String, Any?>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null

        val identity = cell.cellIdentity as? CellIdentityNr ?: return null
        val signal = cell.cellSignalStrength as? android.telephony.CellSignalStrengthNr

        return baseMap("NR", operatorName, cell.isRegistered).plus(
            mapOf(
                "mcc" to identity.mccString,
                "mnc" to identity.mncString,
                "cell_id" to cleanLong(identity.nci)?.toString(),
                "tac_or_lac" to cleanInt(identity.tac)?.toString(),
                "pci_or_psc" to cleanInt(identity.pci)?.toString(),
                "signal_dbm" to signal?.let { cleanSignal(it.dbm) },
                "rsrp_dbm" to signal?.let { cleanSignal(it.ssRsrp) },
                "rsrq_db" to signal?.let { cleanSignal(it.ssRsrq)?.toDouble() },
                "sinr_db" to signal?.let { cleanSignal(it.ssSinr)?.toDouble() },
            )
        )
    }

    private fun wcdmaToMap(cell: CellInfoWcdma, operatorName: String?): Map<String, Any?> {
        val identity = cell.cellIdentity
        val signal = cell.cellSignalStrength

        return baseMap("WCDMA", operatorName, cell.isRegistered).plus(
            mapOf(
                "mcc" to mcc(identity),
                "mnc" to mnc(identity),
                "cell_id" to cleanInt(identity.cid)?.toString(),
                "tac_or_lac" to cleanInt(identity.lac)?.toString(),
                "pci_or_psc" to cleanInt(identity.psc)?.toString(),
                "signal_dbm" to cleanSignal(signal.dbm),
                "rsrp_dbm" to null,
                "rsrq_db" to null,
                "sinr_db" to null,
            )
        )
    }

    private fun gsmToMap(cell: CellInfoGsm, operatorName: String?): Map<String, Any?> {
        val identity = cell.cellIdentity
        val signal = cell.cellSignalStrength

        return baseMap("GSM", operatorName, cell.isRegistered).plus(
            mapOf(
                "mcc" to mcc(identity),
                "mnc" to mnc(identity),
                "cell_id" to cleanInt(identity.cid)?.toString(),
                "tac_or_lac" to cleanInt(identity.lac)?.toString(),
                "pci_or_psc" to null,
                "signal_dbm" to cleanSignal(signal.dbm),
                "rsrp_dbm" to null,
                "rsrq_db" to null,
                "sinr_db" to null,
            )
        )
    }

    private fun baseMap(radioType: String, operatorName: String?, registered: Boolean): Map<String, Any?> {
        return mapOf(
            "radio_type" to radioType,
            "operator_name" to operatorName?.takeIf { it.isNotBlank() },
            "is_registered" to registered,
        )
    }

    private fun mcc(identity: CellIdentityLte): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) identity.mccString else cleanInt(identity.mcc)?.toString()

    private fun mnc(identity: CellIdentityLte): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) identity.mncString else cleanInt(identity.mnc)?.toString()

    private fun mcc(identity: CellIdentityWcdma): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) identity.mccString else cleanInt(identity.mcc)?.toString()

    private fun mnc(identity: CellIdentityWcdma): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) identity.mncString else cleanInt(identity.mnc)?.toString()

    private fun mcc(identity: CellIdentityGsm): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) identity.mccString else cleanInt(identity.mcc)?.toString()

    private fun mnc(identity: CellIdentityGsm): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) identity.mncString else cleanInt(identity.mnc)?.toString()

    private fun lteSinr(signal: CellSignalStrengthLte): Double? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            cleanSignal(signal.rssnr)?.let { it / 10.0 }
        } else {
            null
        }
    }

    private fun cleanInt(value: Int): Int? {
        return value.takeIf { it != Int.MAX_VALUE && it >= 0 }
    }

    private fun cleanSignal(value: Int): Int? {
        return value.takeIf { it != Int.MAX_VALUE }
    }

    private fun cleanLong(value: Long): Long? {
        return value.takeIf { it != Long.MAX_VALUE && it >= 0 }
    }
}
